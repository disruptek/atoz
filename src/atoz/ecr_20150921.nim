
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_591364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_591364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_591364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCheckLayerAvailability_591703 = ref object of OpenApiRestCall_591364
proc url_BatchCheckLayerAvailability_591705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchCheckLayerAvailability_591704(path: JsonNode; query: JsonNode;
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
  var valid_591830 = header.getOrDefault("X-Amz-Target")
  valid_591830 = validateParameter(valid_591830, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability"))
  if valid_591830 != nil:
    section.add "X-Amz-Target", valid_591830
  var valid_591831 = header.getOrDefault("X-Amz-Signature")
  valid_591831 = validateParameter(valid_591831, JString, required = false,
                                 default = nil)
  if valid_591831 != nil:
    section.add "X-Amz-Signature", valid_591831
  var valid_591832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591832 = validateParameter(valid_591832, JString, required = false,
                                 default = nil)
  if valid_591832 != nil:
    section.add "X-Amz-Content-Sha256", valid_591832
  var valid_591833 = header.getOrDefault("X-Amz-Date")
  valid_591833 = validateParameter(valid_591833, JString, required = false,
                                 default = nil)
  if valid_591833 != nil:
    section.add "X-Amz-Date", valid_591833
  var valid_591834 = header.getOrDefault("X-Amz-Credential")
  valid_591834 = validateParameter(valid_591834, JString, required = false,
                                 default = nil)
  if valid_591834 != nil:
    section.add "X-Amz-Credential", valid_591834
  var valid_591835 = header.getOrDefault("X-Amz-Security-Token")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "X-Amz-Security-Token", valid_591835
  var valid_591836 = header.getOrDefault("X-Amz-Algorithm")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "X-Amz-Algorithm", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-SignedHeaders", valid_591837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591861: Call_BatchCheckLayerAvailability_591703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_591861.validator(path, query, header, formData, body)
  let scheme = call_591861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591861.url(scheme.get, call_591861.host, call_591861.base,
                         call_591861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591861, url, valid)

proc call*(call_591932: Call_BatchCheckLayerAvailability_591703; body: JsonNode): Recallable =
  ## batchCheckLayerAvailability
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_591933 = newJObject()
  if body != nil:
    body_591933 = body
  result = call_591932.call(nil, nil, nil, nil, body_591933)

var batchCheckLayerAvailability* = Call_BatchCheckLayerAvailability_591703(
    name: "batchCheckLayerAvailability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability",
    validator: validate_BatchCheckLayerAvailability_591704, base: "/",
    url: url_BatchCheckLayerAvailability_591705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImage_591972 = ref object of OpenApiRestCall_591364
proc url_BatchDeleteImage_591974(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteImage_591973(path: JsonNode; query: JsonNode;
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
  var valid_591975 = header.getOrDefault("X-Amz-Target")
  valid_591975 = validateParameter(valid_591975, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage"))
  if valid_591975 != nil:
    section.add "X-Amz-Target", valid_591975
  var valid_591976 = header.getOrDefault("X-Amz-Signature")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-Signature", valid_591976
  var valid_591977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = nil)
  if valid_591977 != nil:
    section.add "X-Amz-Content-Sha256", valid_591977
  var valid_591978 = header.getOrDefault("X-Amz-Date")
  valid_591978 = validateParameter(valid_591978, JString, required = false,
                                 default = nil)
  if valid_591978 != nil:
    section.add "X-Amz-Date", valid_591978
  var valid_591979 = header.getOrDefault("X-Amz-Credential")
  valid_591979 = validateParameter(valid_591979, JString, required = false,
                                 default = nil)
  if valid_591979 != nil:
    section.add "X-Amz-Credential", valid_591979
  var valid_591980 = header.getOrDefault("X-Amz-Security-Token")
  valid_591980 = validateParameter(valid_591980, JString, required = false,
                                 default = nil)
  if valid_591980 != nil:
    section.add "X-Amz-Security-Token", valid_591980
  var valid_591981 = header.getOrDefault("X-Amz-Algorithm")
  valid_591981 = validateParameter(valid_591981, JString, required = false,
                                 default = nil)
  if valid_591981 != nil:
    section.add "X-Amz-Algorithm", valid_591981
  var valid_591982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "X-Amz-SignedHeaders", valid_591982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591984: Call_BatchDeleteImage_591972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ## 
  let valid = call_591984.validator(path, query, header, formData, body)
  let scheme = call_591984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591984.url(scheme.get, call_591984.host, call_591984.base,
                         call_591984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591984, url, valid)

proc call*(call_591985: Call_BatchDeleteImage_591972; body: JsonNode): Recallable =
  ## batchDeleteImage
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ##   body: JObject (required)
  var body_591986 = newJObject()
  if body != nil:
    body_591986 = body
  result = call_591985.call(nil, nil, nil, nil, body_591986)

var batchDeleteImage* = Call_BatchDeleteImage_591972(name: "batchDeleteImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage",
    validator: validate_BatchDeleteImage_591973, base: "/",
    url: url_BatchDeleteImage_591974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetImage_591987 = ref object of OpenApiRestCall_591364
proc url_BatchGetImage_591989(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetImage_591988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591990 = header.getOrDefault("X-Amz-Target")
  valid_591990 = validateParameter(valid_591990, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchGetImage"))
  if valid_591990 != nil:
    section.add "X-Amz-Target", valid_591990
  var valid_591991 = header.getOrDefault("X-Amz-Signature")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-Signature", valid_591991
  var valid_591992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591992 = validateParameter(valid_591992, JString, required = false,
                                 default = nil)
  if valid_591992 != nil:
    section.add "X-Amz-Content-Sha256", valid_591992
  var valid_591993 = header.getOrDefault("X-Amz-Date")
  valid_591993 = validateParameter(valid_591993, JString, required = false,
                                 default = nil)
  if valid_591993 != nil:
    section.add "X-Amz-Date", valid_591993
  var valid_591994 = header.getOrDefault("X-Amz-Credential")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "X-Amz-Credential", valid_591994
  var valid_591995 = header.getOrDefault("X-Amz-Security-Token")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = nil)
  if valid_591995 != nil:
    section.add "X-Amz-Security-Token", valid_591995
  var valid_591996 = header.getOrDefault("X-Amz-Algorithm")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "X-Amz-Algorithm", valid_591996
  var valid_591997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-SignedHeaders", valid_591997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591999: Call_BatchGetImage_591987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ## 
  let valid = call_591999.validator(path, query, header, formData, body)
  let scheme = call_591999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591999.url(scheme.get, call_591999.host, call_591999.base,
                         call_591999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591999, url, valid)

proc call*(call_592000: Call_BatchGetImage_591987; body: JsonNode): Recallable =
  ## batchGetImage
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ##   body: JObject (required)
  var body_592001 = newJObject()
  if body != nil:
    body_592001 = body
  result = call_592000.call(nil, nil, nil, nil, body_592001)

var batchGetImage* = Call_BatchGetImage_591987(name: "batchGetImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchGetImage",
    validator: validate_BatchGetImage_591988, base: "/", url: url_BatchGetImage_591989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteLayerUpload_592002 = ref object of OpenApiRestCall_591364
proc url_CompleteLayerUpload_592004(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CompleteLayerUpload_592003(path: JsonNode; query: JsonNode;
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
  var valid_592005 = header.getOrDefault("X-Amz-Target")
  valid_592005 = validateParameter(valid_592005, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload"))
  if valid_592005 != nil:
    section.add "X-Amz-Target", valid_592005
  var valid_592006 = header.getOrDefault("X-Amz-Signature")
  valid_592006 = validateParameter(valid_592006, JString, required = false,
                                 default = nil)
  if valid_592006 != nil:
    section.add "X-Amz-Signature", valid_592006
  var valid_592007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592007 = validateParameter(valid_592007, JString, required = false,
                                 default = nil)
  if valid_592007 != nil:
    section.add "X-Amz-Content-Sha256", valid_592007
  var valid_592008 = header.getOrDefault("X-Amz-Date")
  valid_592008 = validateParameter(valid_592008, JString, required = false,
                                 default = nil)
  if valid_592008 != nil:
    section.add "X-Amz-Date", valid_592008
  var valid_592009 = header.getOrDefault("X-Amz-Credential")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = nil)
  if valid_592009 != nil:
    section.add "X-Amz-Credential", valid_592009
  var valid_592010 = header.getOrDefault("X-Amz-Security-Token")
  valid_592010 = validateParameter(valid_592010, JString, required = false,
                                 default = nil)
  if valid_592010 != nil:
    section.add "X-Amz-Security-Token", valid_592010
  var valid_592011 = header.getOrDefault("X-Amz-Algorithm")
  valid_592011 = validateParameter(valid_592011, JString, required = false,
                                 default = nil)
  if valid_592011 != nil:
    section.add "X-Amz-Algorithm", valid_592011
  var valid_592012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592012 = validateParameter(valid_592012, JString, required = false,
                                 default = nil)
  if valid_592012 != nil:
    section.add "X-Amz-SignedHeaders", valid_592012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592014: Call_CompleteLayerUpload_592002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_592014.validator(path, query, header, formData, body)
  let scheme = call_592014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592014.url(scheme.get, call_592014.host, call_592014.base,
                         call_592014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592014, url, valid)

proc call*(call_592015: Call_CompleteLayerUpload_592002; body: JsonNode): Recallable =
  ## completeLayerUpload
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_592016 = newJObject()
  if body != nil:
    body_592016 = body
  result = call_592015.call(nil, nil, nil, nil, body_592016)

var completeLayerUpload* = Call_CompleteLayerUpload_592002(
    name: "completeLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload",
    validator: validate_CompleteLayerUpload_592003, base: "/",
    url: url_CompleteLayerUpload_592004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_592017 = ref object of OpenApiRestCall_591364
proc url_CreateRepository_592019(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRepository_592018(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_592020 = header.getOrDefault("X-Amz-Target")
  valid_592020 = validateParameter(valid_592020, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CreateRepository"))
  if valid_592020 != nil:
    section.add "X-Amz-Target", valid_592020
  var valid_592021 = header.getOrDefault("X-Amz-Signature")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "X-Amz-Signature", valid_592021
  var valid_592022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592022 = validateParameter(valid_592022, JString, required = false,
                                 default = nil)
  if valid_592022 != nil:
    section.add "X-Amz-Content-Sha256", valid_592022
  var valid_592023 = header.getOrDefault("X-Amz-Date")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "X-Amz-Date", valid_592023
  var valid_592024 = header.getOrDefault("X-Amz-Credential")
  valid_592024 = validateParameter(valid_592024, JString, required = false,
                                 default = nil)
  if valid_592024 != nil:
    section.add "X-Amz-Credential", valid_592024
  var valid_592025 = header.getOrDefault("X-Amz-Security-Token")
  valid_592025 = validateParameter(valid_592025, JString, required = false,
                                 default = nil)
  if valid_592025 != nil:
    section.add "X-Amz-Security-Token", valid_592025
  var valid_592026 = header.getOrDefault("X-Amz-Algorithm")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = nil)
  if valid_592026 != nil:
    section.add "X-Amz-Algorithm", valid_592026
  var valid_592027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = nil)
  if valid_592027 != nil:
    section.add "X-Amz-SignedHeaders", valid_592027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592029: Call_CreateRepository_592017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_592029.validator(path, query, header, formData, body)
  let scheme = call_592029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592029.url(scheme.get, call_592029.host, call_592029.base,
                         call_592029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592029, url, valid)

proc call*(call_592030: Call_CreateRepository_592017; body: JsonNode): Recallable =
  ## createRepository
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_592031 = newJObject()
  if body != nil:
    body_592031 = body
  result = call_592030.call(nil, nil, nil, nil, body_592031)

var createRepository* = Call_CreateRepository_592017(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CreateRepository",
    validator: validate_CreateRepository_592018, base: "/",
    url: url_CreateRepository_592019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_592032 = ref object of OpenApiRestCall_591364
proc url_DeleteLifecyclePolicy_592034(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLifecyclePolicy_592033(path: JsonNode; query: JsonNode;
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
  var valid_592035 = header.getOrDefault("X-Amz-Target")
  valid_592035 = validateParameter(valid_592035, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy"))
  if valid_592035 != nil:
    section.add "X-Amz-Target", valid_592035
  var valid_592036 = header.getOrDefault("X-Amz-Signature")
  valid_592036 = validateParameter(valid_592036, JString, required = false,
                                 default = nil)
  if valid_592036 != nil:
    section.add "X-Amz-Signature", valid_592036
  var valid_592037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592037 = validateParameter(valid_592037, JString, required = false,
                                 default = nil)
  if valid_592037 != nil:
    section.add "X-Amz-Content-Sha256", valid_592037
  var valid_592038 = header.getOrDefault("X-Amz-Date")
  valid_592038 = validateParameter(valid_592038, JString, required = false,
                                 default = nil)
  if valid_592038 != nil:
    section.add "X-Amz-Date", valid_592038
  var valid_592039 = header.getOrDefault("X-Amz-Credential")
  valid_592039 = validateParameter(valid_592039, JString, required = false,
                                 default = nil)
  if valid_592039 != nil:
    section.add "X-Amz-Credential", valid_592039
  var valid_592040 = header.getOrDefault("X-Amz-Security-Token")
  valid_592040 = validateParameter(valid_592040, JString, required = false,
                                 default = nil)
  if valid_592040 != nil:
    section.add "X-Amz-Security-Token", valid_592040
  var valid_592041 = header.getOrDefault("X-Amz-Algorithm")
  valid_592041 = validateParameter(valid_592041, JString, required = false,
                                 default = nil)
  if valid_592041 != nil:
    section.add "X-Amz-Algorithm", valid_592041
  var valid_592042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "X-Amz-SignedHeaders", valid_592042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592044: Call_DeleteLifecyclePolicy_592032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy.
  ## 
  let valid = call_592044.validator(path, query, header, formData, body)
  let scheme = call_592044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592044.url(scheme.get, call_592044.host, call_592044.base,
                         call_592044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592044, url, valid)

proc call*(call_592045: Call_DeleteLifecyclePolicy_592032; body: JsonNode): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy.
  ##   body: JObject (required)
  var body_592046 = newJObject()
  if body != nil:
    body_592046 = body
  result = call_592045.call(nil, nil, nil, nil, body_592046)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_592032(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy",
    validator: validate_DeleteLifecyclePolicy_592033, base: "/",
    url: url_DeleteLifecyclePolicy_592034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_592047 = ref object of OpenApiRestCall_591364
proc url_DeleteRepository_592049(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRepository_592048(path: JsonNode; query: JsonNode;
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
  var valid_592050 = header.getOrDefault("X-Amz-Target")
  valid_592050 = validateParameter(valid_592050, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepository"))
  if valid_592050 != nil:
    section.add "X-Amz-Target", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-Signature")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-Signature", valid_592051
  var valid_592052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592052 = validateParameter(valid_592052, JString, required = false,
                                 default = nil)
  if valid_592052 != nil:
    section.add "X-Amz-Content-Sha256", valid_592052
  var valid_592053 = header.getOrDefault("X-Amz-Date")
  valid_592053 = validateParameter(valid_592053, JString, required = false,
                                 default = nil)
  if valid_592053 != nil:
    section.add "X-Amz-Date", valid_592053
  var valid_592054 = header.getOrDefault("X-Amz-Credential")
  valid_592054 = validateParameter(valid_592054, JString, required = false,
                                 default = nil)
  if valid_592054 != nil:
    section.add "X-Amz-Credential", valid_592054
  var valid_592055 = header.getOrDefault("X-Amz-Security-Token")
  valid_592055 = validateParameter(valid_592055, JString, required = false,
                                 default = nil)
  if valid_592055 != nil:
    section.add "X-Amz-Security-Token", valid_592055
  var valid_592056 = header.getOrDefault("X-Amz-Algorithm")
  valid_592056 = validateParameter(valid_592056, JString, required = false,
                                 default = nil)
  if valid_592056 != nil:
    section.add "X-Amz-Algorithm", valid_592056
  var valid_592057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592057 = validateParameter(valid_592057, JString, required = false,
                                 default = nil)
  if valid_592057 != nil:
    section.add "X-Amz-SignedHeaders", valid_592057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592059: Call_DeleteRepository_592047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ## 
  let valid = call_592059.validator(path, query, header, formData, body)
  let scheme = call_592059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592059.url(scheme.get, call_592059.host, call_592059.base,
                         call_592059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592059, url, valid)

proc call*(call_592060: Call_DeleteRepository_592047; body: JsonNode): Recallable =
  ## deleteRepository
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ##   body: JObject (required)
  var body_592061 = newJObject()
  if body != nil:
    body_592061 = body
  result = call_592060.call(nil, nil, nil, nil, body_592061)

var deleteRepository* = Call_DeleteRepository_592047(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepository",
    validator: validate_DeleteRepository_592048, base: "/",
    url: url_DeleteRepository_592049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepositoryPolicy_592062 = ref object of OpenApiRestCall_591364
proc url_DeleteRepositoryPolicy_592064(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRepositoryPolicy_592063(path: JsonNode; query: JsonNode;
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
  var valid_592065 = header.getOrDefault("X-Amz-Target")
  valid_592065 = validateParameter(valid_592065, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy"))
  if valid_592065 != nil:
    section.add "X-Amz-Target", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-Signature")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-Signature", valid_592066
  var valid_592067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = nil)
  if valid_592067 != nil:
    section.add "X-Amz-Content-Sha256", valid_592067
  var valid_592068 = header.getOrDefault("X-Amz-Date")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "X-Amz-Date", valid_592068
  var valid_592069 = header.getOrDefault("X-Amz-Credential")
  valid_592069 = validateParameter(valid_592069, JString, required = false,
                                 default = nil)
  if valid_592069 != nil:
    section.add "X-Amz-Credential", valid_592069
  var valid_592070 = header.getOrDefault("X-Amz-Security-Token")
  valid_592070 = validateParameter(valid_592070, JString, required = false,
                                 default = nil)
  if valid_592070 != nil:
    section.add "X-Amz-Security-Token", valid_592070
  var valid_592071 = header.getOrDefault("X-Amz-Algorithm")
  valid_592071 = validateParameter(valid_592071, JString, required = false,
                                 default = nil)
  if valid_592071 != nil:
    section.add "X-Amz-Algorithm", valid_592071
  var valid_592072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592072 = validateParameter(valid_592072, JString, required = false,
                                 default = nil)
  if valid_592072 != nil:
    section.add "X-Amz-SignedHeaders", valid_592072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592074: Call_DeleteRepositoryPolicy_592062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the repository policy from a specified repository.
  ## 
  let valid = call_592074.validator(path, query, header, formData, body)
  let scheme = call_592074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592074.url(scheme.get, call_592074.host, call_592074.base,
                         call_592074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592074, url, valid)

proc call*(call_592075: Call_DeleteRepositoryPolicy_592062; body: JsonNode): Recallable =
  ## deleteRepositoryPolicy
  ## Deletes the repository policy from a specified repository.
  ##   body: JObject (required)
  var body_592076 = newJObject()
  if body != nil:
    body_592076 = body
  result = call_592075.call(nil, nil, nil, nil, body_592076)

var deleteRepositoryPolicy* = Call_DeleteRepositoryPolicy_592062(
    name: "deleteRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy",
    validator: validate_DeleteRepositoryPolicy_592063, base: "/",
    url: url_DeleteRepositoryPolicy_592064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageScanFindings_592077 = ref object of OpenApiRestCall_591364
proc url_DescribeImageScanFindings_592079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImageScanFindings_592078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the image scan findings for the specified image.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_592080 = query.getOrDefault("nextToken")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "nextToken", valid_592080
  var valid_592081 = query.getOrDefault("maxResults")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "maxResults", valid_592081
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
  var valid_592082 = header.getOrDefault("X-Amz-Target")
  valid_592082 = validateParameter(valid_592082, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings"))
  if valid_592082 != nil:
    section.add "X-Amz-Target", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-Signature")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-Signature", valid_592083
  var valid_592084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = nil)
  if valid_592084 != nil:
    section.add "X-Amz-Content-Sha256", valid_592084
  var valid_592085 = header.getOrDefault("X-Amz-Date")
  valid_592085 = validateParameter(valid_592085, JString, required = false,
                                 default = nil)
  if valid_592085 != nil:
    section.add "X-Amz-Date", valid_592085
  var valid_592086 = header.getOrDefault("X-Amz-Credential")
  valid_592086 = validateParameter(valid_592086, JString, required = false,
                                 default = nil)
  if valid_592086 != nil:
    section.add "X-Amz-Credential", valid_592086
  var valid_592087 = header.getOrDefault("X-Amz-Security-Token")
  valid_592087 = validateParameter(valid_592087, JString, required = false,
                                 default = nil)
  if valid_592087 != nil:
    section.add "X-Amz-Security-Token", valid_592087
  var valid_592088 = header.getOrDefault("X-Amz-Algorithm")
  valid_592088 = validateParameter(valid_592088, JString, required = false,
                                 default = nil)
  if valid_592088 != nil:
    section.add "X-Amz-Algorithm", valid_592088
  var valid_592089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592089 = validateParameter(valid_592089, JString, required = false,
                                 default = nil)
  if valid_592089 != nil:
    section.add "X-Amz-SignedHeaders", valid_592089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592091: Call_DescribeImageScanFindings_592077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the image scan findings for the specified image.
  ## 
  let valid = call_592091.validator(path, query, header, formData, body)
  let scheme = call_592091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592091.url(scheme.get, call_592091.host, call_592091.base,
                         call_592091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592091, url, valid)

proc call*(call_592092: Call_DescribeImageScanFindings_592077; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImageScanFindings
  ## Describes the image scan findings for the specified image.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592093 = newJObject()
  var body_592094 = newJObject()
  add(query_592093, "nextToken", newJString(nextToken))
  if body != nil:
    body_592094 = body
  add(query_592093, "maxResults", newJString(maxResults))
  result = call_592092.call(nil, query_592093, nil, nil, body_592094)

var describeImageScanFindings* = Call_DescribeImageScanFindings_592077(
    name: "describeImageScanFindings", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings",
    validator: validate_DescribeImageScanFindings_592078, base: "/",
    url: url_DescribeImageScanFindings_592079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_592096 = ref object of OpenApiRestCall_591364
proc url_DescribeImages_592098(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImages_592097(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_592099 = query.getOrDefault("nextToken")
  valid_592099 = validateParameter(valid_592099, JString, required = false,
                                 default = nil)
  if valid_592099 != nil:
    section.add "nextToken", valid_592099
  var valid_592100 = query.getOrDefault("maxResults")
  valid_592100 = validateParameter(valid_592100, JString, required = false,
                                 default = nil)
  if valid_592100 != nil:
    section.add "maxResults", valid_592100
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
  var valid_592101 = header.getOrDefault("X-Amz-Target")
  valid_592101 = validateParameter(valid_592101, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImages"))
  if valid_592101 != nil:
    section.add "X-Amz-Target", valid_592101
  var valid_592102 = header.getOrDefault("X-Amz-Signature")
  valid_592102 = validateParameter(valid_592102, JString, required = false,
                                 default = nil)
  if valid_592102 != nil:
    section.add "X-Amz-Signature", valid_592102
  var valid_592103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592103 = validateParameter(valid_592103, JString, required = false,
                                 default = nil)
  if valid_592103 != nil:
    section.add "X-Amz-Content-Sha256", valid_592103
  var valid_592104 = header.getOrDefault("X-Amz-Date")
  valid_592104 = validateParameter(valid_592104, JString, required = false,
                                 default = nil)
  if valid_592104 != nil:
    section.add "X-Amz-Date", valid_592104
  var valid_592105 = header.getOrDefault("X-Amz-Credential")
  valid_592105 = validateParameter(valid_592105, JString, required = false,
                                 default = nil)
  if valid_592105 != nil:
    section.add "X-Amz-Credential", valid_592105
  var valid_592106 = header.getOrDefault("X-Amz-Security-Token")
  valid_592106 = validateParameter(valid_592106, JString, required = false,
                                 default = nil)
  if valid_592106 != nil:
    section.add "X-Amz-Security-Token", valid_592106
  var valid_592107 = header.getOrDefault("X-Amz-Algorithm")
  valid_592107 = validateParameter(valid_592107, JString, required = false,
                                 default = nil)
  if valid_592107 != nil:
    section.add "X-Amz-Algorithm", valid_592107
  var valid_592108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "X-Amz-SignedHeaders", valid_592108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592110: Call_DescribeImages_592096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  let valid = call_592110.validator(path, query, header, formData, body)
  let scheme = call_592110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592110.url(scheme.get, call_592110.host, call_592110.base,
                         call_592110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592110, url, valid)

proc call*(call_592111: Call_DescribeImages_592096; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImages
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592112 = newJObject()
  var body_592113 = newJObject()
  add(query_592112, "nextToken", newJString(nextToken))
  if body != nil:
    body_592113 = body
  add(query_592112, "maxResults", newJString(maxResults))
  result = call_592111.call(nil, query_592112, nil, nil, body_592113)

var describeImages* = Call_DescribeImages_592096(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImages",
    validator: validate_DescribeImages_592097, base: "/", url: url_DescribeImages_592098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositories_592114 = ref object of OpenApiRestCall_591364
proc url_DescribeRepositories_592116(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRepositories_592115(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes image repositories in a registry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_592117 = query.getOrDefault("nextToken")
  valid_592117 = validateParameter(valid_592117, JString, required = false,
                                 default = nil)
  if valid_592117 != nil:
    section.add "nextToken", valid_592117
  var valid_592118 = query.getOrDefault("maxResults")
  valid_592118 = validateParameter(valid_592118, JString, required = false,
                                 default = nil)
  if valid_592118 != nil:
    section.add "maxResults", valid_592118
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
  var valid_592119 = header.getOrDefault("X-Amz-Target")
  valid_592119 = validateParameter(valid_592119, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeRepositories"))
  if valid_592119 != nil:
    section.add "X-Amz-Target", valid_592119
  var valid_592120 = header.getOrDefault("X-Amz-Signature")
  valid_592120 = validateParameter(valid_592120, JString, required = false,
                                 default = nil)
  if valid_592120 != nil:
    section.add "X-Amz-Signature", valid_592120
  var valid_592121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592121 = validateParameter(valid_592121, JString, required = false,
                                 default = nil)
  if valid_592121 != nil:
    section.add "X-Amz-Content-Sha256", valid_592121
  var valid_592122 = header.getOrDefault("X-Amz-Date")
  valid_592122 = validateParameter(valid_592122, JString, required = false,
                                 default = nil)
  if valid_592122 != nil:
    section.add "X-Amz-Date", valid_592122
  var valid_592123 = header.getOrDefault("X-Amz-Credential")
  valid_592123 = validateParameter(valid_592123, JString, required = false,
                                 default = nil)
  if valid_592123 != nil:
    section.add "X-Amz-Credential", valid_592123
  var valid_592124 = header.getOrDefault("X-Amz-Security-Token")
  valid_592124 = validateParameter(valid_592124, JString, required = false,
                                 default = nil)
  if valid_592124 != nil:
    section.add "X-Amz-Security-Token", valid_592124
  var valid_592125 = header.getOrDefault("X-Amz-Algorithm")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = nil)
  if valid_592125 != nil:
    section.add "X-Amz-Algorithm", valid_592125
  var valid_592126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "X-Amz-SignedHeaders", valid_592126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592128: Call_DescribeRepositories_592114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes image repositories in a registry.
  ## 
  let valid = call_592128.validator(path, query, header, formData, body)
  let scheme = call_592128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592128.url(scheme.get, call_592128.host, call_592128.base,
                         call_592128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592128, url, valid)

proc call*(call_592129: Call_DescribeRepositories_592114; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeRepositories
  ## Describes image repositories in a registry.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592130 = newJObject()
  var body_592131 = newJObject()
  add(query_592130, "nextToken", newJString(nextToken))
  if body != nil:
    body_592131 = body
  add(query_592130, "maxResults", newJString(maxResults))
  result = call_592129.call(nil, query_592130, nil, nil, body_592131)

var describeRepositories* = Call_DescribeRepositories_592114(
    name: "describeRepositories", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeRepositories",
    validator: validate_DescribeRepositories_592115, base: "/",
    url: url_DescribeRepositories_592116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizationToken_592132 = ref object of OpenApiRestCall_591364
proc url_GetAuthorizationToken_592134(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizationToken_592133(path: JsonNode; query: JsonNode;
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
  var valid_592135 = header.getOrDefault("X-Amz-Target")
  valid_592135 = validateParameter(valid_592135, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken"))
  if valid_592135 != nil:
    section.add "X-Amz-Target", valid_592135
  var valid_592136 = header.getOrDefault("X-Amz-Signature")
  valid_592136 = validateParameter(valid_592136, JString, required = false,
                                 default = nil)
  if valid_592136 != nil:
    section.add "X-Amz-Signature", valid_592136
  var valid_592137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592137 = validateParameter(valid_592137, JString, required = false,
                                 default = nil)
  if valid_592137 != nil:
    section.add "X-Amz-Content-Sha256", valid_592137
  var valid_592138 = header.getOrDefault("X-Amz-Date")
  valid_592138 = validateParameter(valid_592138, JString, required = false,
                                 default = nil)
  if valid_592138 != nil:
    section.add "X-Amz-Date", valid_592138
  var valid_592139 = header.getOrDefault("X-Amz-Credential")
  valid_592139 = validateParameter(valid_592139, JString, required = false,
                                 default = nil)
  if valid_592139 != nil:
    section.add "X-Amz-Credential", valid_592139
  var valid_592140 = header.getOrDefault("X-Amz-Security-Token")
  valid_592140 = validateParameter(valid_592140, JString, required = false,
                                 default = nil)
  if valid_592140 != nil:
    section.add "X-Amz-Security-Token", valid_592140
  var valid_592141 = header.getOrDefault("X-Amz-Algorithm")
  valid_592141 = validateParameter(valid_592141, JString, required = false,
                                 default = nil)
  if valid_592141 != nil:
    section.add "X-Amz-Algorithm", valid_592141
  var valid_592142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592142 = validateParameter(valid_592142, JString, required = false,
                                 default = nil)
  if valid_592142 != nil:
    section.add "X-Amz-SignedHeaders", valid_592142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592144: Call_GetAuthorizationToken_592132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ## 
  let valid = call_592144.validator(path, query, header, formData, body)
  let scheme = call_592144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592144.url(scheme.get, call_592144.host, call_592144.base,
                         call_592144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592144, url, valid)

proc call*(call_592145: Call_GetAuthorizationToken_592132; body: JsonNode): Recallable =
  ## getAuthorizationToken
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ##   body: JObject (required)
  var body_592146 = newJObject()
  if body != nil:
    body_592146 = body
  result = call_592145.call(nil, nil, nil, nil, body_592146)

var getAuthorizationToken* = Call_GetAuthorizationToken_592132(
    name: "getAuthorizationToken", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken",
    validator: validate_GetAuthorizationToken_592133, base: "/",
    url: url_GetAuthorizationToken_592134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadUrlForLayer_592147 = ref object of OpenApiRestCall_591364
proc url_GetDownloadUrlForLayer_592149(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadUrlForLayer_592148(path: JsonNode; query: JsonNode;
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
  var valid_592150 = header.getOrDefault("X-Amz-Target")
  valid_592150 = validateParameter(valid_592150, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer"))
  if valid_592150 != nil:
    section.add "X-Amz-Target", valid_592150
  var valid_592151 = header.getOrDefault("X-Amz-Signature")
  valid_592151 = validateParameter(valid_592151, JString, required = false,
                                 default = nil)
  if valid_592151 != nil:
    section.add "X-Amz-Signature", valid_592151
  var valid_592152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592152 = validateParameter(valid_592152, JString, required = false,
                                 default = nil)
  if valid_592152 != nil:
    section.add "X-Amz-Content-Sha256", valid_592152
  var valid_592153 = header.getOrDefault("X-Amz-Date")
  valid_592153 = validateParameter(valid_592153, JString, required = false,
                                 default = nil)
  if valid_592153 != nil:
    section.add "X-Amz-Date", valid_592153
  var valid_592154 = header.getOrDefault("X-Amz-Credential")
  valid_592154 = validateParameter(valid_592154, JString, required = false,
                                 default = nil)
  if valid_592154 != nil:
    section.add "X-Amz-Credential", valid_592154
  var valid_592155 = header.getOrDefault("X-Amz-Security-Token")
  valid_592155 = validateParameter(valid_592155, JString, required = false,
                                 default = nil)
  if valid_592155 != nil:
    section.add "X-Amz-Security-Token", valid_592155
  var valid_592156 = header.getOrDefault("X-Amz-Algorithm")
  valid_592156 = validateParameter(valid_592156, JString, required = false,
                                 default = nil)
  if valid_592156 != nil:
    section.add "X-Amz-Algorithm", valid_592156
  var valid_592157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592157 = validateParameter(valid_592157, JString, required = false,
                                 default = nil)
  if valid_592157 != nil:
    section.add "X-Amz-SignedHeaders", valid_592157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592159: Call_GetDownloadUrlForLayer_592147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_592159.validator(path, query, header, formData, body)
  let scheme = call_592159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592159.url(scheme.get, call_592159.host, call_592159.base,
                         call_592159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592159, url, valid)

proc call*(call_592160: Call_GetDownloadUrlForLayer_592147; body: JsonNode): Recallable =
  ## getDownloadUrlForLayer
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_592161 = newJObject()
  if body != nil:
    body_592161 = body
  result = call_592160.call(nil, nil, nil, nil, body_592161)

var getDownloadUrlForLayer* = Call_GetDownloadUrlForLayer_592147(
    name: "getDownloadUrlForLayer", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer",
    validator: validate_GetDownloadUrlForLayer_592148, base: "/",
    url: url_GetDownloadUrlForLayer_592149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_592162 = ref object of OpenApiRestCall_591364
proc url_GetLifecyclePolicy_592164(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLifecyclePolicy_592163(path: JsonNode; query: JsonNode;
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
  var valid_592165 = header.getOrDefault("X-Amz-Target")
  valid_592165 = validateParameter(valid_592165, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy"))
  if valid_592165 != nil:
    section.add "X-Amz-Target", valid_592165
  var valid_592166 = header.getOrDefault("X-Amz-Signature")
  valid_592166 = validateParameter(valid_592166, JString, required = false,
                                 default = nil)
  if valid_592166 != nil:
    section.add "X-Amz-Signature", valid_592166
  var valid_592167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592167 = validateParameter(valid_592167, JString, required = false,
                                 default = nil)
  if valid_592167 != nil:
    section.add "X-Amz-Content-Sha256", valid_592167
  var valid_592168 = header.getOrDefault("X-Amz-Date")
  valid_592168 = validateParameter(valid_592168, JString, required = false,
                                 default = nil)
  if valid_592168 != nil:
    section.add "X-Amz-Date", valid_592168
  var valid_592169 = header.getOrDefault("X-Amz-Credential")
  valid_592169 = validateParameter(valid_592169, JString, required = false,
                                 default = nil)
  if valid_592169 != nil:
    section.add "X-Amz-Credential", valid_592169
  var valid_592170 = header.getOrDefault("X-Amz-Security-Token")
  valid_592170 = validateParameter(valid_592170, JString, required = false,
                                 default = nil)
  if valid_592170 != nil:
    section.add "X-Amz-Security-Token", valid_592170
  var valid_592171 = header.getOrDefault("X-Amz-Algorithm")
  valid_592171 = validateParameter(valid_592171, JString, required = false,
                                 default = nil)
  if valid_592171 != nil:
    section.add "X-Amz-Algorithm", valid_592171
  var valid_592172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592172 = validateParameter(valid_592172, JString, required = false,
                                 default = nil)
  if valid_592172 != nil:
    section.add "X-Amz-SignedHeaders", valid_592172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592174: Call_GetLifecyclePolicy_592162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified lifecycle policy.
  ## 
  let valid = call_592174.validator(path, query, header, formData, body)
  let scheme = call_592174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592174.url(scheme.get, call_592174.host, call_592174.base,
                         call_592174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592174, url, valid)

proc call*(call_592175: Call_GetLifecyclePolicy_592162; body: JsonNode): Recallable =
  ## getLifecyclePolicy
  ## Retrieves the specified lifecycle policy.
  ##   body: JObject (required)
  var body_592176 = newJObject()
  if body != nil:
    body_592176 = body
  result = call_592175.call(nil, nil, nil, nil, body_592176)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_592162(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy",
    validator: validate_GetLifecyclePolicy_592163, base: "/",
    url: url_GetLifecyclePolicy_592164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicyPreview_592177 = ref object of OpenApiRestCall_591364
proc url_GetLifecyclePolicyPreview_592179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLifecyclePolicyPreview_592178(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_592180 = query.getOrDefault("nextToken")
  valid_592180 = validateParameter(valid_592180, JString, required = false,
                                 default = nil)
  if valid_592180 != nil:
    section.add "nextToken", valid_592180
  var valid_592181 = query.getOrDefault("maxResults")
  valid_592181 = validateParameter(valid_592181, JString, required = false,
                                 default = nil)
  if valid_592181 != nil:
    section.add "maxResults", valid_592181
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
  var valid_592182 = header.getOrDefault("X-Amz-Target")
  valid_592182 = validateParameter(valid_592182, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview"))
  if valid_592182 != nil:
    section.add "X-Amz-Target", valid_592182
  var valid_592183 = header.getOrDefault("X-Amz-Signature")
  valid_592183 = validateParameter(valid_592183, JString, required = false,
                                 default = nil)
  if valid_592183 != nil:
    section.add "X-Amz-Signature", valid_592183
  var valid_592184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592184 = validateParameter(valid_592184, JString, required = false,
                                 default = nil)
  if valid_592184 != nil:
    section.add "X-Amz-Content-Sha256", valid_592184
  var valid_592185 = header.getOrDefault("X-Amz-Date")
  valid_592185 = validateParameter(valid_592185, JString, required = false,
                                 default = nil)
  if valid_592185 != nil:
    section.add "X-Amz-Date", valid_592185
  var valid_592186 = header.getOrDefault("X-Amz-Credential")
  valid_592186 = validateParameter(valid_592186, JString, required = false,
                                 default = nil)
  if valid_592186 != nil:
    section.add "X-Amz-Credential", valid_592186
  var valid_592187 = header.getOrDefault("X-Amz-Security-Token")
  valid_592187 = validateParameter(valid_592187, JString, required = false,
                                 default = nil)
  if valid_592187 != nil:
    section.add "X-Amz-Security-Token", valid_592187
  var valid_592188 = header.getOrDefault("X-Amz-Algorithm")
  valid_592188 = validateParameter(valid_592188, JString, required = false,
                                 default = nil)
  if valid_592188 != nil:
    section.add "X-Amz-Algorithm", valid_592188
  var valid_592189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592189 = validateParameter(valid_592189, JString, required = false,
                                 default = nil)
  if valid_592189 != nil:
    section.add "X-Amz-SignedHeaders", valid_592189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592191: Call_GetLifecyclePolicyPreview_592177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  let valid = call_592191.validator(path, query, header, formData, body)
  let scheme = call_592191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592191.url(scheme.get, call_592191.host, call_592191.base,
                         call_592191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592191, url, valid)

proc call*(call_592192: Call_GetLifecyclePolicyPreview_592177; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getLifecyclePolicyPreview
  ## Retrieves the results of the specified lifecycle policy preview request.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592193 = newJObject()
  var body_592194 = newJObject()
  add(query_592193, "nextToken", newJString(nextToken))
  if body != nil:
    body_592194 = body
  add(query_592193, "maxResults", newJString(maxResults))
  result = call_592192.call(nil, query_592193, nil, nil, body_592194)

var getLifecyclePolicyPreview* = Call_GetLifecyclePolicyPreview_592177(
    name: "getLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview",
    validator: validate_GetLifecyclePolicyPreview_592178, base: "/",
    url: url_GetLifecyclePolicyPreview_592179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryPolicy_592195 = ref object of OpenApiRestCall_591364
proc url_GetRepositoryPolicy_592197(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRepositoryPolicy_592196(path: JsonNode; query: JsonNode;
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
  var valid_592198 = header.getOrDefault("X-Amz-Target")
  valid_592198 = validateParameter(valid_592198, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy"))
  if valid_592198 != nil:
    section.add "X-Amz-Target", valid_592198
  var valid_592199 = header.getOrDefault("X-Amz-Signature")
  valid_592199 = validateParameter(valid_592199, JString, required = false,
                                 default = nil)
  if valid_592199 != nil:
    section.add "X-Amz-Signature", valid_592199
  var valid_592200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592200 = validateParameter(valid_592200, JString, required = false,
                                 default = nil)
  if valid_592200 != nil:
    section.add "X-Amz-Content-Sha256", valid_592200
  var valid_592201 = header.getOrDefault("X-Amz-Date")
  valid_592201 = validateParameter(valid_592201, JString, required = false,
                                 default = nil)
  if valid_592201 != nil:
    section.add "X-Amz-Date", valid_592201
  var valid_592202 = header.getOrDefault("X-Amz-Credential")
  valid_592202 = validateParameter(valid_592202, JString, required = false,
                                 default = nil)
  if valid_592202 != nil:
    section.add "X-Amz-Credential", valid_592202
  var valid_592203 = header.getOrDefault("X-Amz-Security-Token")
  valid_592203 = validateParameter(valid_592203, JString, required = false,
                                 default = nil)
  if valid_592203 != nil:
    section.add "X-Amz-Security-Token", valid_592203
  var valid_592204 = header.getOrDefault("X-Amz-Algorithm")
  valid_592204 = validateParameter(valid_592204, JString, required = false,
                                 default = nil)
  if valid_592204 != nil:
    section.add "X-Amz-Algorithm", valid_592204
  var valid_592205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592205 = validateParameter(valid_592205, JString, required = false,
                                 default = nil)
  if valid_592205 != nil:
    section.add "X-Amz-SignedHeaders", valid_592205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592207: Call_GetRepositoryPolicy_592195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the repository policy for a specified repository.
  ## 
  let valid = call_592207.validator(path, query, header, formData, body)
  let scheme = call_592207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592207.url(scheme.get, call_592207.host, call_592207.base,
                         call_592207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592207, url, valid)

proc call*(call_592208: Call_GetRepositoryPolicy_592195; body: JsonNode): Recallable =
  ## getRepositoryPolicy
  ## Retrieves the repository policy for a specified repository.
  ##   body: JObject (required)
  var body_592209 = newJObject()
  if body != nil:
    body_592209 = body
  result = call_592208.call(nil, nil, nil, nil, body_592209)

var getRepositoryPolicy* = Call_GetRepositoryPolicy_592195(
    name: "getRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy",
    validator: validate_GetRepositoryPolicy_592196, base: "/",
    url: url_GetRepositoryPolicy_592197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateLayerUpload_592210 = ref object of OpenApiRestCall_591364
proc url_InitiateLayerUpload_592212(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InitiateLayerUpload_592211(path: JsonNode; query: JsonNode;
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
  var valid_592213 = header.getOrDefault("X-Amz-Target")
  valid_592213 = validateParameter(valid_592213, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload"))
  if valid_592213 != nil:
    section.add "X-Amz-Target", valid_592213
  var valid_592214 = header.getOrDefault("X-Amz-Signature")
  valid_592214 = validateParameter(valid_592214, JString, required = false,
                                 default = nil)
  if valid_592214 != nil:
    section.add "X-Amz-Signature", valid_592214
  var valid_592215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592215 = validateParameter(valid_592215, JString, required = false,
                                 default = nil)
  if valid_592215 != nil:
    section.add "X-Amz-Content-Sha256", valid_592215
  var valid_592216 = header.getOrDefault("X-Amz-Date")
  valid_592216 = validateParameter(valid_592216, JString, required = false,
                                 default = nil)
  if valid_592216 != nil:
    section.add "X-Amz-Date", valid_592216
  var valid_592217 = header.getOrDefault("X-Amz-Credential")
  valid_592217 = validateParameter(valid_592217, JString, required = false,
                                 default = nil)
  if valid_592217 != nil:
    section.add "X-Amz-Credential", valid_592217
  var valid_592218 = header.getOrDefault("X-Amz-Security-Token")
  valid_592218 = validateParameter(valid_592218, JString, required = false,
                                 default = nil)
  if valid_592218 != nil:
    section.add "X-Amz-Security-Token", valid_592218
  var valid_592219 = header.getOrDefault("X-Amz-Algorithm")
  valid_592219 = validateParameter(valid_592219, JString, required = false,
                                 default = nil)
  if valid_592219 != nil:
    section.add "X-Amz-Algorithm", valid_592219
  var valid_592220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592220 = validateParameter(valid_592220, JString, required = false,
                                 default = nil)
  if valid_592220 != nil:
    section.add "X-Amz-SignedHeaders", valid_592220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592222: Call_InitiateLayerUpload_592210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_592222.validator(path, query, header, formData, body)
  let scheme = call_592222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592222.url(scheme.get, call_592222.host, call_592222.base,
                         call_592222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592222, url, valid)

proc call*(call_592223: Call_InitiateLayerUpload_592210; body: JsonNode): Recallable =
  ## initiateLayerUpload
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_592224 = newJObject()
  if body != nil:
    body_592224 = body
  result = call_592223.call(nil, nil, nil, nil, body_592224)

var initiateLayerUpload* = Call_InitiateLayerUpload_592210(
    name: "initiateLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload",
    validator: validate_InitiateLayerUpload_592211, base: "/",
    url: url_InitiateLayerUpload_592212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_592225 = ref object of OpenApiRestCall_591364
proc url_ListImages_592227(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListImages_592226(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_592228 = query.getOrDefault("nextToken")
  valid_592228 = validateParameter(valid_592228, JString, required = false,
                                 default = nil)
  if valid_592228 != nil:
    section.add "nextToken", valid_592228
  var valid_592229 = query.getOrDefault("maxResults")
  valid_592229 = validateParameter(valid_592229, JString, required = false,
                                 default = nil)
  if valid_592229 != nil:
    section.add "maxResults", valid_592229
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
  var valid_592230 = header.getOrDefault("X-Amz-Target")
  valid_592230 = validateParameter(valid_592230, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListImages"))
  if valid_592230 != nil:
    section.add "X-Amz-Target", valid_592230
  var valid_592231 = header.getOrDefault("X-Amz-Signature")
  valid_592231 = validateParameter(valid_592231, JString, required = false,
                                 default = nil)
  if valid_592231 != nil:
    section.add "X-Amz-Signature", valid_592231
  var valid_592232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592232 = validateParameter(valid_592232, JString, required = false,
                                 default = nil)
  if valid_592232 != nil:
    section.add "X-Amz-Content-Sha256", valid_592232
  var valid_592233 = header.getOrDefault("X-Amz-Date")
  valid_592233 = validateParameter(valid_592233, JString, required = false,
                                 default = nil)
  if valid_592233 != nil:
    section.add "X-Amz-Date", valid_592233
  var valid_592234 = header.getOrDefault("X-Amz-Credential")
  valid_592234 = validateParameter(valid_592234, JString, required = false,
                                 default = nil)
  if valid_592234 != nil:
    section.add "X-Amz-Credential", valid_592234
  var valid_592235 = header.getOrDefault("X-Amz-Security-Token")
  valid_592235 = validateParameter(valid_592235, JString, required = false,
                                 default = nil)
  if valid_592235 != nil:
    section.add "X-Amz-Security-Token", valid_592235
  var valid_592236 = header.getOrDefault("X-Amz-Algorithm")
  valid_592236 = validateParameter(valid_592236, JString, required = false,
                                 default = nil)
  if valid_592236 != nil:
    section.add "X-Amz-Algorithm", valid_592236
  var valid_592237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592237 = validateParameter(valid_592237, JString, required = false,
                                 default = nil)
  if valid_592237 != nil:
    section.add "X-Amz-SignedHeaders", valid_592237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592239: Call_ListImages_592225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  let valid = call_592239.validator(path, query, header, formData, body)
  let scheme = call_592239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592239.url(scheme.get, call_592239.host, call_592239.base,
                         call_592239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592239, url, valid)

proc call*(call_592240: Call_ListImages_592225; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImages
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_592241 = newJObject()
  var body_592242 = newJObject()
  add(query_592241, "nextToken", newJString(nextToken))
  if body != nil:
    body_592242 = body
  add(query_592241, "maxResults", newJString(maxResults))
  result = call_592240.call(nil, query_592241, nil, nil, body_592242)

var listImages* = Call_ListImages_592225(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListImages",
                                      validator: validate_ListImages_592226,
                                      base: "/", url: url_ListImages_592227,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_592243 = ref object of OpenApiRestCall_591364
proc url_ListTagsForResource_592245(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_592244(path: JsonNode; query: JsonNode;
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
  var valid_592246 = header.getOrDefault("X-Amz-Target")
  valid_592246 = validateParameter(valid_592246, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListTagsForResource"))
  if valid_592246 != nil:
    section.add "X-Amz-Target", valid_592246
  var valid_592247 = header.getOrDefault("X-Amz-Signature")
  valid_592247 = validateParameter(valid_592247, JString, required = false,
                                 default = nil)
  if valid_592247 != nil:
    section.add "X-Amz-Signature", valid_592247
  var valid_592248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592248 = validateParameter(valid_592248, JString, required = false,
                                 default = nil)
  if valid_592248 != nil:
    section.add "X-Amz-Content-Sha256", valid_592248
  var valid_592249 = header.getOrDefault("X-Amz-Date")
  valid_592249 = validateParameter(valid_592249, JString, required = false,
                                 default = nil)
  if valid_592249 != nil:
    section.add "X-Amz-Date", valid_592249
  var valid_592250 = header.getOrDefault("X-Amz-Credential")
  valid_592250 = validateParameter(valid_592250, JString, required = false,
                                 default = nil)
  if valid_592250 != nil:
    section.add "X-Amz-Credential", valid_592250
  var valid_592251 = header.getOrDefault("X-Amz-Security-Token")
  valid_592251 = validateParameter(valid_592251, JString, required = false,
                                 default = nil)
  if valid_592251 != nil:
    section.add "X-Amz-Security-Token", valid_592251
  var valid_592252 = header.getOrDefault("X-Amz-Algorithm")
  valid_592252 = validateParameter(valid_592252, JString, required = false,
                                 default = nil)
  if valid_592252 != nil:
    section.add "X-Amz-Algorithm", valid_592252
  var valid_592253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592253 = validateParameter(valid_592253, JString, required = false,
                                 default = nil)
  if valid_592253 != nil:
    section.add "X-Amz-SignedHeaders", valid_592253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592255: Call_ListTagsForResource_592243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECR resource.
  ## 
  let valid = call_592255.validator(path, query, header, formData, body)
  let scheme = call_592255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592255.url(scheme.get, call_592255.host, call_592255.base,
                         call_592255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592255, url, valid)

proc call*(call_592256: Call_ListTagsForResource_592243; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECR resource.
  ##   body: JObject (required)
  var body_592257 = newJObject()
  if body != nil:
    body_592257 = body
  result = call_592256.call(nil, nil, nil, nil, body_592257)

var listTagsForResource* = Call_ListTagsForResource_592243(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListTagsForResource",
    validator: validate_ListTagsForResource_592244, base: "/",
    url: url_ListTagsForResource_592245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImage_592258 = ref object of OpenApiRestCall_591364
proc url_PutImage_592260(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutImage_592259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592261 = header.getOrDefault("X-Amz-Target")
  valid_592261 = validateParameter(valid_592261, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImage"))
  if valid_592261 != nil:
    section.add "X-Amz-Target", valid_592261
  var valid_592262 = header.getOrDefault("X-Amz-Signature")
  valid_592262 = validateParameter(valid_592262, JString, required = false,
                                 default = nil)
  if valid_592262 != nil:
    section.add "X-Amz-Signature", valid_592262
  var valid_592263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592263 = validateParameter(valid_592263, JString, required = false,
                                 default = nil)
  if valid_592263 != nil:
    section.add "X-Amz-Content-Sha256", valid_592263
  var valid_592264 = header.getOrDefault("X-Amz-Date")
  valid_592264 = validateParameter(valid_592264, JString, required = false,
                                 default = nil)
  if valid_592264 != nil:
    section.add "X-Amz-Date", valid_592264
  var valid_592265 = header.getOrDefault("X-Amz-Credential")
  valid_592265 = validateParameter(valid_592265, JString, required = false,
                                 default = nil)
  if valid_592265 != nil:
    section.add "X-Amz-Credential", valid_592265
  var valid_592266 = header.getOrDefault("X-Amz-Security-Token")
  valid_592266 = validateParameter(valid_592266, JString, required = false,
                                 default = nil)
  if valid_592266 != nil:
    section.add "X-Amz-Security-Token", valid_592266
  var valid_592267 = header.getOrDefault("X-Amz-Algorithm")
  valid_592267 = validateParameter(valid_592267, JString, required = false,
                                 default = nil)
  if valid_592267 != nil:
    section.add "X-Amz-Algorithm", valid_592267
  var valid_592268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592268 = validateParameter(valid_592268, JString, required = false,
                                 default = nil)
  if valid_592268 != nil:
    section.add "X-Amz-SignedHeaders", valid_592268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592270: Call_PutImage_592258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_592270.validator(path, query, header, formData, body)
  let scheme = call_592270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592270.url(scheme.get, call_592270.host, call_592270.base,
                         call_592270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592270, url, valid)

proc call*(call_592271: Call_PutImage_592258; body: JsonNode): Recallable =
  ## putImage
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_592272 = newJObject()
  if body != nil:
    body_592272 = body
  result = call_592271.call(nil, nil, nil, nil, body_592272)

var putImage* = Call_PutImage_592258(name: "putImage", meth: HttpMethod.HttpPost,
                                  host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImage",
                                  validator: validate_PutImage_592259, base: "/",
                                  url: url_PutImage_592260,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageScanningConfiguration_592273 = ref object of OpenApiRestCall_591364
proc url_PutImageScanningConfiguration_592275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutImageScanningConfiguration_592274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the image scanning configuration for a repository.
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
  var valid_592276 = header.getOrDefault("X-Amz-Target")
  valid_592276 = validateParameter(valid_592276, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration"))
  if valid_592276 != nil:
    section.add "X-Amz-Target", valid_592276
  var valid_592277 = header.getOrDefault("X-Amz-Signature")
  valid_592277 = validateParameter(valid_592277, JString, required = false,
                                 default = nil)
  if valid_592277 != nil:
    section.add "X-Amz-Signature", valid_592277
  var valid_592278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592278 = validateParameter(valid_592278, JString, required = false,
                                 default = nil)
  if valid_592278 != nil:
    section.add "X-Amz-Content-Sha256", valid_592278
  var valid_592279 = header.getOrDefault("X-Amz-Date")
  valid_592279 = validateParameter(valid_592279, JString, required = false,
                                 default = nil)
  if valid_592279 != nil:
    section.add "X-Amz-Date", valid_592279
  var valid_592280 = header.getOrDefault("X-Amz-Credential")
  valid_592280 = validateParameter(valid_592280, JString, required = false,
                                 default = nil)
  if valid_592280 != nil:
    section.add "X-Amz-Credential", valid_592280
  var valid_592281 = header.getOrDefault("X-Amz-Security-Token")
  valid_592281 = validateParameter(valid_592281, JString, required = false,
                                 default = nil)
  if valid_592281 != nil:
    section.add "X-Amz-Security-Token", valid_592281
  var valid_592282 = header.getOrDefault("X-Amz-Algorithm")
  valid_592282 = validateParameter(valid_592282, JString, required = false,
                                 default = nil)
  if valid_592282 != nil:
    section.add "X-Amz-Algorithm", valid_592282
  var valid_592283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592283 = validateParameter(valid_592283, JString, required = false,
                                 default = nil)
  if valid_592283 != nil:
    section.add "X-Amz-SignedHeaders", valid_592283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592285: Call_PutImageScanningConfiguration_592273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image scanning configuration for a repository.
  ## 
  let valid = call_592285.validator(path, query, header, formData, body)
  let scheme = call_592285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592285.url(scheme.get, call_592285.host, call_592285.base,
                         call_592285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592285, url, valid)

proc call*(call_592286: Call_PutImageScanningConfiguration_592273; body: JsonNode): Recallable =
  ## putImageScanningConfiguration
  ## Updates the image scanning configuration for a repository.
  ##   body: JObject (required)
  var body_592287 = newJObject()
  if body != nil:
    body_592287 = body
  result = call_592286.call(nil, nil, nil, nil, body_592287)

var putImageScanningConfiguration* = Call_PutImageScanningConfiguration_592273(
    name: "putImageScanningConfiguration", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration",
    validator: validate_PutImageScanningConfiguration_592274, base: "/",
    url: url_PutImageScanningConfiguration_592275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageTagMutability_592288 = ref object of OpenApiRestCall_591364
proc url_PutImageTagMutability_592290(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutImageTagMutability_592289(path: JsonNode; query: JsonNode;
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
  var valid_592291 = header.getOrDefault("X-Amz-Target")
  valid_592291 = validateParameter(valid_592291, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability"))
  if valid_592291 != nil:
    section.add "X-Amz-Target", valid_592291
  var valid_592292 = header.getOrDefault("X-Amz-Signature")
  valid_592292 = validateParameter(valid_592292, JString, required = false,
                                 default = nil)
  if valid_592292 != nil:
    section.add "X-Amz-Signature", valid_592292
  var valid_592293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592293 = validateParameter(valid_592293, JString, required = false,
                                 default = nil)
  if valid_592293 != nil:
    section.add "X-Amz-Content-Sha256", valid_592293
  var valid_592294 = header.getOrDefault("X-Amz-Date")
  valid_592294 = validateParameter(valid_592294, JString, required = false,
                                 default = nil)
  if valid_592294 != nil:
    section.add "X-Amz-Date", valid_592294
  var valid_592295 = header.getOrDefault("X-Amz-Credential")
  valid_592295 = validateParameter(valid_592295, JString, required = false,
                                 default = nil)
  if valid_592295 != nil:
    section.add "X-Amz-Credential", valid_592295
  var valid_592296 = header.getOrDefault("X-Amz-Security-Token")
  valid_592296 = validateParameter(valid_592296, JString, required = false,
                                 default = nil)
  if valid_592296 != nil:
    section.add "X-Amz-Security-Token", valid_592296
  var valid_592297 = header.getOrDefault("X-Amz-Algorithm")
  valid_592297 = validateParameter(valid_592297, JString, required = false,
                                 default = nil)
  if valid_592297 != nil:
    section.add "X-Amz-Algorithm", valid_592297
  var valid_592298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592298 = validateParameter(valid_592298, JString, required = false,
                                 default = nil)
  if valid_592298 != nil:
    section.add "X-Amz-SignedHeaders", valid_592298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592300: Call_PutImageTagMutability_592288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image tag mutability settings for a repository.
  ## 
  let valid = call_592300.validator(path, query, header, formData, body)
  let scheme = call_592300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592300.url(scheme.get, call_592300.host, call_592300.base,
                         call_592300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592300, url, valid)

proc call*(call_592301: Call_PutImageTagMutability_592288; body: JsonNode): Recallable =
  ## putImageTagMutability
  ## Updates the image tag mutability settings for a repository.
  ##   body: JObject (required)
  var body_592302 = newJObject()
  if body != nil:
    body_592302 = body
  result = call_592301.call(nil, nil, nil, nil, body_592302)

var putImageTagMutability* = Call_PutImageTagMutability_592288(
    name: "putImageTagMutability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability",
    validator: validate_PutImageTagMutability_592289, base: "/",
    url: url_PutImageTagMutability_592290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecyclePolicy_592303 = ref object of OpenApiRestCall_591364
proc url_PutLifecyclePolicy_592305(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLifecyclePolicy_592304(path: JsonNode; query: JsonNode;
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
  var valid_592306 = header.getOrDefault("X-Amz-Target")
  valid_592306 = validateParameter(valid_592306, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy"))
  if valid_592306 != nil:
    section.add "X-Amz-Target", valid_592306
  var valid_592307 = header.getOrDefault("X-Amz-Signature")
  valid_592307 = validateParameter(valid_592307, JString, required = false,
                                 default = nil)
  if valid_592307 != nil:
    section.add "X-Amz-Signature", valid_592307
  var valid_592308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592308 = validateParameter(valid_592308, JString, required = false,
                                 default = nil)
  if valid_592308 != nil:
    section.add "X-Amz-Content-Sha256", valid_592308
  var valid_592309 = header.getOrDefault("X-Amz-Date")
  valid_592309 = validateParameter(valid_592309, JString, required = false,
                                 default = nil)
  if valid_592309 != nil:
    section.add "X-Amz-Date", valid_592309
  var valid_592310 = header.getOrDefault("X-Amz-Credential")
  valid_592310 = validateParameter(valid_592310, JString, required = false,
                                 default = nil)
  if valid_592310 != nil:
    section.add "X-Amz-Credential", valid_592310
  var valid_592311 = header.getOrDefault("X-Amz-Security-Token")
  valid_592311 = validateParameter(valid_592311, JString, required = false,
                                 default = nil)
  if valid_592311 != nil:
    section.add "X-Amz-Security-Token", valid_592311
  var valid_592312 = header.getOrDefault("X-Amz-Algorithm")
  valid_592312 = validateParameter(valid_592312, JString, required = false,
                                 default = nil)
  if valid_592312 != nil:
    section.add "X-Amz-Algorithm", valid_592312
  var valid_592313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592313 = validateParameter(valid_592313, JString, required = false,
                                 default = nil)
  if valid_592313 != nil:
    section.add "X-Amz-SignedHeaders", valid_592313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592315: Call_PutLifecyclePolicy_592303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ## 
  let valid = call_592315.validator(path, query, header, formData, body)
  let scheme = call_592315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592315.url(scheme.get, call_592315.host, call_592315.base,
                         call_592315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592315, url, valid)

proc call*(call_592316: Call_PutLifecyclePolicy_592303; body: JsonNode): Recallable =
  ## putLifecyclePolicy
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ##   body: JObject (required)
  var body_592317 = newJObject()
  if body != nil:
    body_592317 = body
  result = call_592316.call(nil, nil, nil, nil, body_592317)

var putLifecyclePolicy* = Call_PutLifecyclePolicy_592303(
    name: "putLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy",
    validator: validate_PutLifecyclePolicy_592304, base: "/",
    url: url_PutLifecyclePolicy_592305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRepositoryPolicy_592318 = ref object of OpenApiRestCall_591364
proc url_SetRepositoryPolicy_592320(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetRepositoryPolicy_592319(path: JsonNode; query: JsonNode;
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
  var valid_592321 = header.getOrDefault("X-Amz-Target")
  valid_592321 = validateParameter(valid_592321, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy"))
  if valid_592321 != nil:
    section.add "X-Amz-Target", valid_592321
  var valid_592322 = header.getOrDefault("X-Amz-Signature")
  valid_592322 = validateParameter(valid_592322, JString, required = false,
                                 default = nil)
  if valid_592322 != nil:
    section.add "X-Amz-Signature", valid_592322
  var valid_592323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592323 = validateParameter(valid_592323, JString, required = false,
                                 default = nil)
  if valid_592323 != nil:
    section.add "X-Amz-Content-Sha256", valid_592323
  var valid_592324 = header.getOrDefault("X-Amz-Date")
  valid_592324 = validateParameter(valid_592324, JString, required = false,
                                 default = nil)
  if valid_592324 != nil:
    section.add "X-Amz-Date", valid_592324
  var valid_592325 = header.getOrDefault("X-Amz-Credential")
  valid_592325 = validateParameter(valid_592325, JString, required = false,
                                 default = nil)
  if valid_592325 != nil:
    section.add "X-Amz-Credential", valid_592325
  var valid_592326 = header.getOrDefault("X-Amz-Security-Token")
  valid_592326 = validateParameter(valid_592326, JString, required = false,
                                 default = nil)
  if valid_592326 != nil:
    section.add "X-Amz-Security-Token", valid_592326
  var valid_592327 = header.getOrDefault("X-Amz-Algorithm")
  valid_592327 = validateParameter(valid_592327, JString, required = false,
                                 default = nil)
  if valid_592327 != nil:
    section.add "X-Amz-Algorithm", valid_592327
  var valid_592328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592328 = validateParameter(valid_592328, JString, required = false,
                                 default = nil)
  if valid_592328 != nil:
    section.add "X-Amz-SignedHeaders", valid_592328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592330: Call_SetRepositoryPolicy_592318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_592330.validator(path, query, header, formData, body)
  let scheme = call_592330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592330.url(scheme.get, call_592330.host, call_592330.base,
                         call_592330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592330, url, valid)

proc call*(call_592331: Call_SetRepositoryPolicy_592318; body: JsonNode): Recallable =
  ## setRepositoryPolicy
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_592332 = newJObject()
  if body != nil:
    body_592332 = body
  result = call_592331.call(nil, nil, nil, nil, body_592332)

var setRepositoryPolicy* = Call_SetRepositoryPolicy_592318(
    name: "setRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy",
    validator: validate_SetRepositoryPolicy_592319, base: "/",
    url: url_SetRepositoryPolicy_592320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageScan_592333 = ref object of OpenApiRestCall_591364
proc url_StartImageScan_592335(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImageScan_592334(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Starts an image vulnerability scan.
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
  var valid_592336 = header.getOrDefault("X-Amz-Target")
  valid_592336 = validateParameter(valid_592336, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartImageScan"))
  if valid_592336 != nil:
    section.add "X-Amz-Target", valid_592336
  var valid_592337 = header.getOrDefault("X-Amz-Signature")
  valid_592337 = validateParameter(valid_592337, JString, required = false,
                                 default = nil)
  if valid_592337 != nil:
    section.add "X-Amz-Signature", valid_592337
  var valid_592338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592338 = validateParameter(valid_592338, JString, required = false,
                                 default = nil)
  if valid_592338 != nil:
    section.add "X-Amz-Content-Sha256", valid_592338
  var valid_592339 = header.getOrDefault("X-Amz-Date")
  valid_592339 = validateParameter(valid_592339, JString, required = false,
                                 default = nil)
  if valid_592339 != nil:
    section.add "X-Amz-Date", valid_592339
  var valid_592340 = header.getOrDefault("X-Amz-Credential")
  valid_592340 = validateParameter(valid_592340, JString, required = false,
                                 default = nil)
  if valid_592340 != nil:
    section.add "X-Amz-Credential", valid_592340
  var valid_592341 = header.getOrDefault("X-Amz-Security-Token")
  valid_592341 = validateParameter(valid_592341, JString, required = false,
                                 default = nil)
  if valid_592341 != nil:
    section.add "X-Amz-Security-Token", valid_592341
  var valid_592342 = header.getOrDefault("X-Amz-Algorithm")
  valid_592342 = validateParameter(valid_592342, JString, required = false,
                                 default = nil)
  if valid_592342 != nil:
    section.add "X-Amz-Algorithm", valid_592342
  var valid_592343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592343 = validateParameter(valid_592343, JString, required = false,
                                 default = nil)
  if valid_592343 != nil:
    section.add "X-Amz-SignedHeaders", valid_592343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592345: Call_StartImageScan_592333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an image vulnerability scan.
  ## 
  let valid = call_592345.validator(path, query, header, formData, body)
  let scheme = call_592345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592345.url(scheme.get, call_592345.host, call_592345.base,
                         call_592345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592345, url, valid)

proc call*(call_592346: Call_StartImageScan_592333; body: JsonNode): Recallable =
  ## startImageScan
  ## Starts an image vulnerability scan.
  ##   body: JObject (required)
  var body_592347 = newJObject()
  if body != nil:
    body_592347 = body
  result = call_592346.call(nil, nil, nil, nil, body_592347)

var startImageScan* = Call_StartImageScan_592333(name: "startImageScan",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartImageScan",
    validator: validate_StartImageScan_592334, base: "/", url: url_StartImageScan_592335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLifecyclePolicyPreview_592348 = ref object of OpenApiRestCall_591364
proc url_StartLifecyclePolicyPreview_592350(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartLifecyclePolicyPreview_592349(path: JsonNode; query: JsonNode;
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
  var valid_592351 = header.getOrDefault("X-Amz-Target")
  valid_592351 = validateParameter(valid_592351, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview"))
  if valid_592351 != nil:
    section.add "X-Amz-Target", valid_592351
  var valid_592352 = header.getOrDefault("X-Amz-Signature")
  valid_592352 = validateParameter(valid_592352, JString, required = false,
                                 default = nil)
  if valid_592352 != nil:
    section.add "X-Amz-Signature", valid_592352
  var valid_592353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592353 = validateParameter(valid_592353, JString, required = false,
                                 default = nil)
  if valid_592353 != nil:
    section.add "X-Amz-Content-Sha256", valid_592353
  var valid_592354 = header.getOrDefault("X-Amz-Date")
  valid_592354 = validateParameter(valid_592354, JString, required = false,
                                 default = nil)
  if valid_592354 != nil:
    section.add "X-Amz-Date", valid_592354
  var valid_592355 = header.getOrDefault("X-Amz-Credential")
  valid_592355 = validateParameter(valid_592355, JString, required = false,
                                 default = nil)
  if valid_592355 != nil:
    section.add "X-Amz-Credential", valid_592355
  var valid_592356 = header.getOrDefault("X-Amz-Security-Token")
  valid_592356 = validateParameter(valid_592356, JString, required = false,
                                 default = nil)
  if valid_592356 != nil:
    section.add "X-Amz-Security-Token", valid_592356
  var valid_592357 = header.getOrDefault("X-Amz-Algorithm")
  valid_592357 = validateParameter(valid_592357, JString, required = false,
                                 default = nil)
  if valid_592357 != nil:
    section.add "X-Amz-Algorithm", valid_592357
  var valid_592358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592358 = validateParameter(valid_592358, JString, required = false,
                                 default = nil)
  if valid_592358 != nil:
    section.add "X-Amz-SignedHeaders", valid_592358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592360: Call_StartLifecyclePolicyPreview_592348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ## 
  let valid = call_592360.validator(path, query, header, formData, body)
  let scheme = call_592360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592360.url(scheme.get, call_592360.host, call_592360.base,
                         call_592360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592360, url, valid)

proc call*(call_592361: Call_StartLifecyclePolicyPreview_592348; body: JsonNode): Recallable =
  ## startLifecyclePolicyPreview
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ##   body: JObject (required)
  var body_592362 = newJObject()
  if body != nil:
    body_592362 = body
  result = call_592361.call(nil, nil, nil, nil, body_592362)

var startLifecyclePolicyPreview* = Call_StartLifecyclePolicyPreview_592348(
    name: "startLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview",
    validator: validate_StartLifecyclePolicyPreview_592349, base: "/",
    url: url_StartLifecyclePolicyPreview_592350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_592363 = ref object of OpenApiRestCall_591364
proc url_TagResource_592365(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_592364(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592366 = header.getOrDefault("X-Amz-Target")
  valid_592366 = validateParameter(valid_592366, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.TagResource"))
  if valid_592366 != nil:
    section.add "X-Amz-Target", valid_592366
  var valid_592367 = header.getOrDefault("X-Amz-Signature")
  valid_592367 = validateParameter(valid_592367, JString, required = false,
                                 default = nil)
  if valid_592367 != nil:
    section.add "X-Amz-Signature", valid_592367
  var valid_592368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592368 = validateParameter(valid_592368, JString, required = false,
                                 default = nil)
  if valid_592368 != nil:
    section.add "X-Amz-Content-Sha256", valid_592368
  var valid_592369 = header.getOrDefault("X-Amz-Date")
  valid_592369 = validateParameter(valid_592369, JString, required = false,
                                 default = nil)
  if valid_592369 != nil:
    section.add "X-Amz-Date", valid_592369
  var valid_592370 = header.getOrDefault("X-Amz-Credential")
  valid_592370 = validateParameter(valid_592370, JString, required = false,
                                 default = nil)
  if valid_592370 != nil:
    section.add "X-Amz-Credential", valid_592370
  var valid_592371 = header.getOrDefault("X-Amz-Security-Token")
  valid_592371 = validateParameter(valid_592371, JString, required = false,
                                 default = nil)
  if valid_592371 != nil:
    section.add "X-Amz-Security-Token", valid_592371
  var valid_592372 = header.getOrDefault("X-Amz-Algorithm")
  valid_592372 = validateParameter(valid_592372, JString, required = false,
                                 default = nil)
  if valid_592372 != nil:
    section.add "X-Amz-Algorithm", valid_592372
  var valid_592373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592373 = validateParameter(valid_592373, JString, required = false,
                                 default = nil)
  if valid_592373 != nil:
    section.add "X-Amz-SignedHeaders", valid_592373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592375: Call_TagResource_592363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_592375.validator(path, query, header, formData, body)
  let scheme = call_592375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592375.url(scheme.get, call_592375.host, call_592375.base,
                         call_592375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592375, url, valid)

proc call*(call_592376: Call_TagResource_592363; body: JsonNode): Recallable =
  ## tagResource
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ##   body: JObject (required)
  var body_592377 = newJObject()
  if body != nil:
    body_592377 = body
  result = call_592376.call(nil, nil, nil, nil, body_592377)

var tagResource* = Call_TagResource_592363(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.TagResource",
                                        validator: validate_TagResource_592364,
                                        base: "/", url: url_TagResource_592365,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_592378 = ref object of OpenApiRestCall_591364
proc url_UntagResource_592380(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_592379(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592381 = header.getOrDefault("X-Amz-Target")
  valid_592381 = validateParameter(valid_592381, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UntagResource"))
  if valid_592381 != nil:
    section.add "X-Amz-Target", valid_592381
  var valid_592382 = header.getOrDefault("X-Amz-Signature")
  valid_592382 = validateParameter(valid_592382, JString, required = false,
                                 default = nil)
  if valid_592382 != nil:
    section.add "X-Amz-Signature", valid_592382
  var valid_592383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592383 = validateParameter(valid_592383, JString, required = false,
                                 default = nil)
  if valid_592383 != nil:
    section.add "X-Amz-Content-Sha256", valid_592383
  var valid_592384 = header.getOrDefault("X-Amz-Date")
  valid_592384 = validateParameter(valid_592384, JString, required = false,
                                 default = nil)
  if valid_592384 != nil:
    section.add "X-Amz-Date", valid_592384
  var valid_592385 = header.getOrDefault("X-Amz-Credential")
  valid_592385 = validateParameter(valid_592385, JString, required = false,
                                 default = nil)
  if valid_592385 != nil:
    section.add "X-Amz-Credential", valid_592385
  var valid_592386 = header.getOrDefault("X-Amz-Security-Token")
  valid_592386 = validateParameter(valid_592386, JString, required = false,
                                 default = nil)
  if valid_592386 != nil:
    section.add "X-Amz-Security-Token", valid_592386
  var valid_592387 = header.getOrDefault("X-Amz-Algorithm")
  valid_592387 = validateParameter(valid_592387, JString, required = false,
                                 default = nil)
  if valid_592387 != nil:
    section.add "X-Amz-Algorithm", valid_592387
  var valid_592388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592388 = validateParameter(valid_592388, JString, required = false,
                                 default = nil)
  if valid_592388 != nil:
    section.add "X-Amz-SignedHeaders", valid_592388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592390: Call_UntagResource_592378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_592390.validator(path, query, header, formData, body)
  let scheme = call_592390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592390.url(scheme.get, call_592390.host, call_592390.base,
                         call_592390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592390, url, valid)

proc call*(call_592391: Call_UntagResource_592378; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_592392 = newJObject()
  if body != nil:
    body_592392 = body
  result = call_592391.call(nil, nil, nil, nil, body_592392)

var untagResource* = Call_UntagResource_592378(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UntagResource",
    validator: validate_UntagResource_592379, base: "/", url: url_UntagResource_592380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadLayerPart_592393 = ref object of OpenApiRestCall_591364
proc url_UploadLayerPart_592395(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UploadLayerPart_592394(path: JsonNode; query: JsonNode;
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
  var valid_592396 = header.getOrDefault("X-Amz-Target")
  valid_592396 = validateParameter(valid_592396, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UploadLayerPart"))
  if valid_592396 != nil:
    section.add "X-Amz-Target", valid_592396
  var valid_592397 = header.getOrDefault("X-Amz-Signature")
  valid_592397 = validateParameter(valid_592397, JString, required = false,
                                 default = nil)
  if valid_592397 != nil:
    section.add "X-Amz-Signature", valid_592397
  var valid_592398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592398 = validateParameter(valid_592398, JString, required = false,
                                 default = nil)
  if valid_592398 != nil:
    section.add "X-Amz-Content-Sha256", valid_592398
  var valid_592399 = header.getOrDefault("X-Amz-Date")
  valid_592399 = validateParameter(valid_592399, JString, required = false,
                                 default = nil)
  if valid_592399 != nil:
    section.add "X-Amz-Date", valid_592399
  var valid_592400 = header.getOrDefault("X-Amz-Credential")
  valid_592400 = validateParameter(valid_592400, JString, required = false,
                                 default = nil)
  if valid_592400 != nil:
    section.add "X-Amz-Credential", valid_592400
  var valid_592401 = header.getOrDefault("X-Amz-Security-Token")
  valid_592401 = validateParameter(valid_592401, JString, required = false,
                                 default = nil)
  if valid_592401 != nil:
    section.add "X-Amz-Security-Token", valid_592401
  var valid_592402 = header.getOrDefault("X-Amz-Algorithm")
  valid_592402 = validateParameter(valid_592402, JString, required = false,
                                 default = nil)
  if valid_592402 != nil:
    section.add "X-Amz-Algorithm", valid_592402
  var valid_592403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592403 = validateParameter(valid_592403, JString, required = false,
                                 default = nil)
  if valid_592403 != nil:
    section.add "X-Amz-SignedHeaders", valid_592403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592405: Call_UploadLayerPart_592393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_592405.validator(path, query, header, formData, body)
  let scheme = call_592405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592405.url(scheme.get, call_592405.host, call_592405.base,
                         call_592405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592405, url, valid)

proc call*(call_592406: Call_UploadLayerPart_592393; body: JsonNode): Recallable =
  ## uploadLayerPart
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_592407 = newJObject()
  if body != nil:
    body_592407 = body
  result = call_592406.call(nil, nil, nil, nil, body_592407)

var uploadLayerPart* = Call_UploadLayerPart_592393(name: "uploadLayerPart",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UploadLayerPart",
    validator: validate_UploadLayerPart_592394, base: "/", url: url_UploadLayerPart_592395,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
