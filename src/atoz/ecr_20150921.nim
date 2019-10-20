
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  Call_BatchCheckLayerAvailability_592703 = ref object of OpenApiRestCall_592364
proc url_BatchCheckLayerAvailability_592705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchCheckLayerAvailability_592704(path: JsonNode; query: JsonNode;
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
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_BatchCheckLayerAvailability_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_BatchCheckLayerAvailability_592703; body: JsonNode): Recallable =
  ## batchCheckLayerAvailability
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var batchCheckLayerAvailability* = Call_BatchCheckLayerAvailability_592703(
    name: "batchCheckLayerAvailability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability",
    validator: validate_BatchCheckLayerAvailability_592704, base: "/",
    url: url_BatchCheckLayerAvailability_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImage_592972 = ref object of OpenApiRestCall_592364
proc url_BatchDeleteImage_592974(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDeleteImage_592973(path: JsonNode; query: JsonNode;
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
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_BatchDeleteImage_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_BatchDeleteImage_592972; body: JsonNode): Recallable =
  ## batchDeleteImage
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var batchDeleteImage* = Call_BatchDeleteImage_592972(name: "batchDeleteImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage",
    validator: validate_BatchDeleteImage_592973, base: "/",
    url: url_BatchDeleteImage_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetImage_592987 = ref object of OpenApiRestCall_592364
proc url_BatchGetImage_592989(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetImage_592988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchGetImage"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_BatchGetImage_592987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_BatchGetImage_592987; body: JsonNode): Recallable =
  ## batchGetImage
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var batchGetImage* = Call_BatchGetImage_592987(name: "batchGetImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchGetImage",
    validator: validate_BatchGetImage_592988, base: "/", url: url_BatchGetImage_592989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteLayerUpload_593002 = ref object of OpenApiRestCall_592364
proc url_CompleteLayerUpload_593004(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CompleteLayerUpload_593003(path: JsonNode; query: JsonNode;
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
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_CompleteLayerUpload_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_CompleteLayerUpload_593002; body: JsonNode): Recallable =
  ## completeLayerUpload
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var completeLayerUpload* = Call_CompleteLayerUpload_593002(
    name: "completeLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload",
    validator: validate_CompleteLayerUpload_593003, base: "/",
    url: url_CompleteLayerUpload_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_593017 = ref object of OpenApiRestCall_592364
proc url_CreateRepository_593019(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRepository_593018(path: JsonNode; query: JsonNode;
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
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CreateRepository"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_CreateRepository_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an image repository.
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_CreateRepository_593017; body: JsonNode): Recallable =
  ## createRepository
  ## Creates an image repository.
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var createRepository* = Call_CreateRepository_593017(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CreateRepository",
    validator: validate_CreateRepository_593018, base: "/",
    url: url_CreateRepository_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_593032 = ref object of OpenApiRestCall_592364
proc url_DeleteLifecyclePolicy_593034(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLifecyclePolicy_593033(path: JsonNode; query: JsonNode;
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
  var valid_593035 = header.getOrDefault("X-Amz-Target")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy"))
  if valid_593035 != nil:
    section.add "X-Amz-Target", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_DeleteLifecyclePolicy_593032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy.
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_DeleteLifecyclePolicy_593032; body: JsonNode): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy.
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_593032(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy",
    validator: validate_DeleteLifecyclePolicy_593033, base: "/",
    url: url_DeleteLifecyclePolicy_593034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_593047 = ref object of OpenApiRestCall_592364
proc url_DeleteRepository_593049(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRepository_593048(path: JsonNode; query: JsonNode;
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
  var valid_593050 = header.getOrDefault("X-Amz-Target")
  valid_593050 = validateParameter(valid_593050, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepository"))
  if valid_593050 != nil:
    section.add "X-Amz-Target", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_DeleteRepository_593047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_DeleteRepository_593047; body: JsonNode): Recallable =
  ## deleteRepository
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var deleteRepository* = Call_DeleteRepository_593047(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepository",
    validator: validate_DeleteRepository_593048, base: "/",
    url: url_DeleteRepository_593049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepositoryPolicy_593062 = ref object of OpenApiRestCall_592364
proc url_DeleteRepositoryPolicy_593064(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRepositoryPolicy_593063(path: JsonNode; query: JsonNode;
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
  var valid_593065 = header.getOrDefault("X-Amz-Target")
  valid_593065 = validateParameter(valid_593065, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy"))
  if valid_593065 != nil:
    section.add "X-Amz-Target", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_DeleteRepositoryPolicy_593062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the repository policy from a specified repository.
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_DeleteRepositoryPolicy_593062; body: JsonNode): Recallable =
  ## deleteRepositoryPolicy
  ## Deletes the repository policy from a specified repository.
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var deleteRepositoryPolicy* = Call_DeleteRepositoryPolicy_593062(
    name: "deleteRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy",
    validator: validate_DeleteRepositoryPolicy_593063, base: "/",
    url: url_DeleteRepositoryPolicy_593064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_593077 = ref object of OpenApiRestCall_592364
proc url_DescribeImages_593079(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeImages_593078(path: JsonNode; query: JsonNode;
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
  var valid_593080 = query.getOrDefault("nextToken")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "nextToken", valid_593080
  var valid_593081 = query.getOrDefault("maxResults")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "maxResults", valid_593081
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
  var valid_593082 = header.getOrDefault("X-Amz-Target")
  valid_593082 = validateParameter(valid_593082, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImages"))
  if valid_593082 != nil:
    section.add "X-Amz-Target", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Signature")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Signature", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Content-Sha256", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Date")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Date", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Credential")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Credential", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Security-Token")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Security-Token", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Algorithm")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Algorithm", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-SignedHeaders", valid_593089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593091: Call_DescribeImages_593077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  let valid = call_593091.validator(path, query, header, formData, body)
  let scheme = call_593091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593091.url(scheme.get, call_593091.host, call_593091.base,
                         call_593091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593091, url, valid)

proc call*(call_593092: Call_DescribeImages_593077; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImages
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593093 = newJObject()
  var body_593094 = newJObject()
  add(query_593093, "nextToken", newJString(nextToken))
  if body != nil:
    body_593094 = body
  add(query_593093, "maxResults", newJString(maxResults))
  result = call_593092.call(nil, query_593093, nil, nil, body_593094)

var describeImages* = Call_DescribeImages_593077(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImages",
    validator: validate_DescribeImages_593078, base: "/", url: url_DescribeImages_593079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositories_593096 = ref object of OpenApiRestCall_592364
proc url_DescribeRepositories_593098(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRepositories_593097(path: JsonNode; query: JsonNode;
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
  var valid_593099 = query.getOrDefault("nextToken")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "nextToken", valid_593099
  var valid_593100 = query.getOrDefault("maxResults")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "maxResults", valid_593100
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
  var valid_593101 = header.getOrDefault("X-Amz-Target")
  valid_593101 = validateParameter(valid_593101, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeRepositories"))
  if valid_593101 != nil:
    section.add "X-Amz-Target", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Signature")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Signature", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Content-Sha256", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Date")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Date", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Credential")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Credential", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Security-Token")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Security-Token", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Algorithm")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Algorithm", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-SignedHeaders", valid_593108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593110: Call_DescribeRepositories_593096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes image repositories in a registry.
  ## 
  let valid = call_593110.validator(path, query, header, formData, body)
  let scheme = call_593110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593110.url(scheme.get, call_593110.host, call_593110.base,
                         call_593110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593110, url, valid)

proc call*(call_593111: Call_DescribeRepositories_593096; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeRepositories
  ## Describes image repositories in a registry.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593112 = newJObject()
  var body_593113 = newJObject()
  add(query_593112, "nextToken", newJString(nextToken))
  if body != nil:
    body_593113 = body
  add(query_593112, "maxResults", newJString(maxResults))
  result = call_593111.call(nil, query_593112, nil, nil, body_593113)

var describeRepositories* = Call_DescribeRepositories_593096(
    name: "describeRepositories", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeRepositories",
    validator: validate_DescribeRepositories_593097, base: "/",
    url: url_DescribeRepositories_593098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizationToken_593114 = ref object of OpenApiRestCall_592364
proc url_GetAuthorizationToken_593116(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizationToken_593115(path: JsonNode; query: JsonNode;
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
  var valid_593117 = header.getOrDefault("X-Amz-Target")
  valid_593117 = validateParameter(valid_593117, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken"))
  if valid_593117 != nil:
    section.add "X-Amz-Target", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Signature")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Signature", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Content-Sha256", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Date")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Date", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Credential")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Credential", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Security-Token")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Security-Token", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Algorithm")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Algorithm", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-SignedHeaders", valid_593124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593126: Call_GetAuthorizationToken_593114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ## 
  let valid = call_593126.validator(path, query, header, formData, body)
  let scheme = call_593126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593126.url(scheme.get, call_593126.host, call_593126.base,
                         call_593126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593126, url, valid)

proc call*(call_593127: Call_GetAuthorizationToken_593114; body: JsonNode): Recallable =
  ## getAuthorizationToken
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ##   body: JObject (required)
  var body_593128 = newJObject()
  if body != nil:
    body_593128 = body
  result = call_593127.call(nil, nil, nil, nil, body_593128)

var getAuthorizationToken* = Call_GetAuthorizationToken_593114(
    name: "getAuthorizationToken", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken",
    validator: validate_GetAuthorizationToken_593115, base: "/",
    url: url_GetAuthorizationToken_593116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadUrlForLayer_593129 = ref object of OpenApiRestCall_592364
proc url_GetDownloadUrlForLayer_593131(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadUrlForLayer_593130(path: JsonNode; query: JsonNode;
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
  var valid_593132 = header.getOrDefault("X-Amz-Target")
  valid_593132 = validateParameter(valid_593132, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer"))
  if valid_593132 != nil:
    section.add "X-Amz-Target", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Signature")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Signature", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Content-Sha256", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Date")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Date", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Credential")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Credential", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Security-Token")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Security-Token", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Algorithm")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Algorithm", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-SignedHeaders", valid_593139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593141: Call_GetDownloadUrlForLayer_593129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_593141.validator(path, query, header, formData, body)
  let scheme = call_593141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593141.url(scheme.get, call_593141.host, call_593141.base,
                         call_593141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593141, url, valid)

proc call*(call_593142: Call_GetDownloadUrlForLayer_593129; body: JsonNode): Recallable =
  ## getDownloadUrlForLayer
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_593143 = newJObject()
  if body != nil:
    body_593143 = body
  result = call_593142.call(nil, nil, nil, nil, body_593143)

var getDownloadUrlForLayer* = Call_GetDownloadUrlForLayer_593129(
    name: "getDownloadUrlForLayer", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer",
    validator: validate_GetDownloadUrlForLayer_593130, base: "/",
    url: url_GetDownloadUrlForLayer_593131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_593144 = ref object of OpenApiRestCall_592364
proc url_GetLifecyclePolicy_593146(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLifecyclePolicy_593145(path: JsonNode; query: JsonNode;
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
  var valid_593147 = header.getOrDefault("X-Amz-Target")
  valid_593147 = validateParameter(valid_593147, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy"))
  if valid_593147 != nil:
    section.add "X-Amz-Target", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Signature")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Signature", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Content-Sha256", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-Date")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Date", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Credential")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Credential", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Security-Token")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Security-Token", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Algorithm")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Algorithm", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-SignedHeaders", valid_593154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593156: Call_GetLifecyclePolicy_593144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified lifecycle policy.
  ## 
  let valid = call_593156.validator(path, query, header, formData, body)
  let scheme = call_593156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593156.url(scheme.get, call_593156.host, call_593156.base,
                         call_593156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593156, url, valid)

proc call*(call_593157: Call_GetLifecyclePolicy_593144; body: JsonNode): Recallable =
  ## getLifecyclePolicy
  ## Retrieves the specified lifecycle policy.
  ##   body: JObject (required)
  var body_593158 = newJObject()
  if body != nil:
    body_593158 = body
  result = call_593157.call(nil, nil, nil, nil, body_593158)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_593144(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy",
    validator: validate_GetLifecyclePolicy_593145, base: "/",
    url: url_GetLifecyclePolicy_593146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicyPreview_593159 = ref object of OpenApiRestCall_592364
proc url_GetLifecyclePolicyPreview_593161(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLifecyclePolicyPreview_593160(path: JsonNode; query: JsonNode;
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
  var valid_593162 = header.getOrDefault("X-Amz-Target")
  valid_593162 = validateParameter(valid_593162, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview"))
  if valid_593162 != nil:
    section.add "X-Amz-Target", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Signature")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Signature", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Content-Sha256", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Date")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Date", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Credential")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Credential", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Security-Token")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Security-Token", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Algorithm")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Algorithm", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-SignedHeaders", valid_593169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593171: Call_GetLifecyclePolicyPreview_593159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  let valid = call_593171.validator(path, query, header, formData, body)
  let scheme = call_593171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593171.url(scheme.get, call_593171.host, call_593171.base,
                         call_593171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593171, url, valid)

proc call*(call_593172: Call_GetLifecyclePolicyPreview_593159; body: JsonNode): Recallable =
  ## getLifecyclePolicyPreview
  ## Retrieves the results of the specified lifecycle policy preview request.
  ##   body: JObject (required)
  var body_593173 = newJObject()
  if body != nil:
    body_593173 = body
  result = call_593172.call(nil, nil, nil, nil, body_593173)

var getLifecyclePolicyPreview* = Call_GetLifecyclePolicyPreview_593159(
    name: "getLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview",
    validator: validate_GetLifecyclePolicyPreview_593160, base: "/",
    url: url_GetLifecyclePolicyPreview_593161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryPolicy_593174 = ref object of OpenApiRestCall_592364
proc url_GetRepositoryPolicy_593176(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRepositoryPolicy_593175(path: JsonNode; query: JsonNode;
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
  var valid_593177 = header.getOrDefault("X-Amz-Target")
  valid_593177 = validateParameter(valid_593177, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy"))
  if valid_593177 != nil:
    section.add "X-Amz-Target", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Signature")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Signature", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Content-Sha256", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Date")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Date", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Credential")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Credential", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Security-Token")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Security-Token", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Algorithm")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Algorithm", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-SignedHeaders", valid_593184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593186: Call_GetRepositoryPolicy_593174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the repository policy for a specified repository.
  ## 
  let valid = call_593186.validator(path, query, header, formData, body)
  let scheme = call_593186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593186.url(scheme.get, call_593186.host, call_593186.base,
                         call_593186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593186, url, valid)

proc call*(call_593187: Call_GetRepositoryPolicy_593174; body: JsonNode): Recallable =
  ## getRepositoryPolicy
  ## Retrieves the repository policy for a specified repository.
  ##   body: JObject (required)
  var body_593188 = newJObject()
  if body != nil:
    body_593188 = body
  result = call_593187.call(nil, nil, nil, nil, body_593188)

var getRepositoryPolicy* = Call_GetRepositoryPolicy_593174(
    name: "getRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy",
    validator: validate_GetRepositoryPolicy_593175, base: "/",
    url: url_GetRepositoryPolicy_593176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateLayerUpload_593189 = ref object of OpenApiRestCall_592364
proc url_InitiateLayerUpload_593191(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InitiateLayerUpload_593190(path: JsonNode; query: JsonNode;
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
  var valid_593192 = header.getOrDefault("X-Amz-Target")
  valid_593192 = validateParameter(valid_593192, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload"))
  if valid_593192 != nil:
    section.add "X-Amz-Target", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Signature")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Signature", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Content-Sha256", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Date")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Date", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Credential")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Credential", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Security-Token")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Security-Token", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Algorithm")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Algorithm", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-SignedHeaders", valid_593199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593201: Call_InitiateLayerUpload_593189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_593201.validator(path, query, header, formData, body)
  let scheme = call_593201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593201.url(scheme.get, call_593201.host, call_593201.base,
                         call_593201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593201, url, valid)

proc call*(call_593202: Call_InitiateLayerUpload_593189; body: JsonNode): Recallable =
  ## initiateLayerUpload
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_593203 = newJObject()
  if body != nil:
    body_593203 = body
  result = call_593202.call(nil, nil, nil, nil, body_593203)

var initiateLayerUpload* = Call_InitiateLayerUpload_593189(
    name: "initiateLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload",
    validator: validate_InitiateLayerUpload_593190, base: "/",
    url: url_InitiateLayerUpload_593191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_593204 = ref object of OpenApiRestCall_592364
proc url_ListImages_593206(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListImages_593205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593207 = query.getOrDefault("nextToken")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "nextToken", valid_593207
  var valid_593208 = query.getOrDefault("maxResults")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "maxResults", valid_593208
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
  var valid_593209 = header.getOrDefault("X-Amz-Target")
  valid_593209 = validateParameter(valid_593209, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListImages"))
  if valid_593209 != nil:
    section.add "X-Amz-Target", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Signature")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Signature", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Content-Sha256", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Date")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Date", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Credential")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Credential", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Security-Token")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Security-Token", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Algorithm")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Algorithm", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-SignedHeaders", valid_593216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593218: Call_ListImages_593204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  let valid = call_593218.validator(path, query, header, formData, body)
  let scheme = call_593218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593218.url(scheme.get, call_593218.host, call_593218.base,
                         call_593218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593218, url, valid)

proc call*(call_593219: Call_ListImages_593204; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImages
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593220 = newJObject()
  var body_593221 = newJObject()
  add(query_593220, "nextToken", newJString(nextToken))
  if body != nil:
    body_593221 = body
  add(query_593220, "maxResults", newJString(maxResults))
  result = call_593219.call(nil, query_593220, nil, nil, body_593221)

var listImages* = Call_ListImages_593204(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListImages",
                                      validator: validate_ListImages_593205,
                                      base: "/", url: url_ListImages_593206,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593222 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593224(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593223(path: JsonNode; query: JsonNode;
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
  var valid_593225 = header.getOrDefault("X-Amz-Target")
  valid_593225 = validateParameter(valid_593225, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListTagsForResource"))
  if valid_593225 != nil:
    section.add "X-Amz-Target", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Signature")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Signature", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Content-Sha256", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Date")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Date", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Credential")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Credential", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Security-Token")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Security-Token", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Algorithm")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Algorithm", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-SignedHeaders", valid_593232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593234: Call_ListTagsForResource_593222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECR resource.
  ## 
  let valid = call_593234.validator(path, query, header, formData, body)
  let scheme = call_593234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593234.url(scheme.get, call_593234.host, call_593234.base,
                         call_593234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593234, url, valid)

proc call*(call_593235: Call_ListTagsForResource_593222; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECR resource.
  ##   body: JObject (required)
  var body_593236 = newJObject()
  if body != nil:
    body_593236 = body
  result = call_593235.call(nil, nil, nil, nil, body_593236)

var listTagsForResource* = Call_ListTagsForResource_593222(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListTagsForResource",
    validator: validate_ListTagsForResource_593223, base: "/",
    url: url_ListTagsForResource_593224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImage_593237 = ref object of OpenApiRestCall_592364
proc url_PutImage_593239(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutImage_593238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593240 = header.getOrDefault("X-Amz-Target")
  valid_593240 = validateParameter(valid_593240, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImage"))
  if valid_593240 != nil:
    section.add "X-Amz-Target", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Signature")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Signature", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Content-Sha256", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Date")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Date", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Credential")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Credential", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Security-Token")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Security-Token", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Algorithm")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Algorithm", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-SignedHeaders", valid_593247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593249: Call_PutImage_593237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_593249.validator(path, query, header, formData, body)
  let scheme = call_593249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593249.url(scheme.get, call_593249.host, call_593249.base,
                         call_593249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593249, url, valid)

proc call*(call_593250: Call_PutImage_593237; body: JsonNode): Recallable =
  ## putImage
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_593251 = newJObject()
  if body != nil:
    body_593251 = body
  result = call_593250.call(nil, nil, nil, nil, body_593251)

var putImage* = Call_PutImage_593237(name: "putImage", meth: HttpMethod.HttpPost,
                                  host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImage",
                                  validator: validate_PutImage_593238, base: "/",
                                  url: url_PutImage_593239,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageTagMutability_593252 = ref object of OpenApiRestCall_592364
proc url_PutImageTagMutability_593254(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutImageTagMutability_593253(path: JsonNode; query: JsonNode;
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
  var valid_593255 = header.getOrDefault("X-Amz-Target")
  valid_593255 = validateParameter(valid_593255, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability"))
  if valid_593255 != nil:
    section.add "X-Amz-Target", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Signature")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Signature", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Content-Sha256", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Date")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Date", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Credential")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Credential", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Security-Token")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Security-Token", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Algorithm")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Algorithm", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-SignedHeaders", valid_593262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593264: Call_PutImageTagMutability_593252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image tag mutability settings for a repository.
  ## 
  let valid = call_593264.validator(path, query, header, formData, body)
  let scheme = call_593264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593264.url(scheme.get, call_593264.host, call_593264.base,
                         call_593264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593264, url, valid)

proc call*(call_593265: Call_PutImageTagMutability_593252; body: JsonNode): Recallable =
  ## putImageTagMutability
  ## Updates the image tag mutability settings for a repository.
  ##   body: JObject (required)
  var body_593266 = newJObject()
  if body != nil:
    body_593266 = body
  result = call_593265.call(nil, nil, nil, nil, body_593266)

var putImageTagMutability* = Call_PutImageTagMutability_593252(
    name: "putImageTagMutability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability",
    validator: validate_PutImageTagMutability_593253, base: "/",
    url: url_PutImageTagMutability_593254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecyclePolicy_593267 = ref object of OpenApiRestCall_592364
proc url_PutLifecyclePolicy_593269(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLifecyclePolicy_593268(path: JsonNode; query: JsonNode;
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
  var valid_593270 = header.getOrDefault("X-Amz-Target")
  valid_593270 = validateParameter(valid_593270, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy"))
  if valid_593270 != nil:
    section.add "X-Amz-Target", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Signature")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Signature", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Content-Sha256", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Date")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Date", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Credential")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Credential", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Security-Token")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Security-Token", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Algorithm")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Algorithm", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-SignedHeaders", valid_593277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593279: Call_PutLifecyclePolicy_593267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ## 
  let valid = call_593279.validator(path, query, header, formData, body)
  let scheme = call_593279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593279.url(scheme.get, call_593279.host, call_593279.base,
                         call_593279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593279, url, valid)

proc call*(call_593280: Call_PutLifecyclePolicy_593267; body: JsonNode): Recallable =
  ## putLifecyclePolicy
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ##   body: JObject (required)
  var body_593281 = newJObject()
  if body != nil:
    body_593281 = body
  result = call_593280.call(nil, nil, nil, nil, body_593281)

var putLifecyclePolicy* = Call_PutLifecyclePolicy_593267(
    name: "putLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy",
    validator: validate_PutLifecyclePolicy_593268, base: "/",
    url: url_PutLifecyclePolicy_593269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRepositoryPolicy_593282 = ref object of OpenApiRestCall_592364
proc url_SetRepositoryPolicy_593284(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SetRepositoryPolicy_593283(path: JsonNode; query: JsonNode;
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
  var valid_593285 = header.getOrDefault("X-Amz-Target")
  valid_593285 = validateParameter(valid_593285, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy"))
  if valid_593285 != nil:
    section.add "X-Amz-Target", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Signature")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Signature", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Content-Sha256", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Date")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Date", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Credential")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Credential", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Security-Token")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Security-Token", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Algorithm")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Algorithm", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-SignedHeaders", valid_593292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593294: Call_SetRepositoryPolicy_593282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_593294.validator(path, query, header, formData, body)
  let scheme = call_593294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593294.url(scheme.get, call_593294.host, call_593294.base,
                         call_593294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593294, url, valid)

proc call*(call_593295: Call_SetRepositoryPolicy_593282; body: JsonNode): Recallable =
  ## setRepositoryPolicy
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_593296 = newJObject()
  if body != nil:
    body_593296 = body
  result = call_593295.call(nil, nil, nil, nil, body_593296)

var setRepositoryPolicy* = Call_SetRepositoryPolicy_593282(
    name: "setRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy",
    validator: validate_SetRepositoryPolicy_593283, base: "/",
    url: url_SetRepositoryPolicy_593284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLifecyclePolicyPreview_593297 = ref object of OpenApiRestCall_592364
proc url_StartLifecyclePolicyPreview_593299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartLifecyclePolicyPreview_593298(path: JsonNode; query: JsonNode;
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
  var valid_593300 = header.getOrDefault("X-Amz-Target")
  valid_593300 = validateParameter(valid_593300, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview"))
  if valid_593300 != nil:
    section.add "X-Amz-Target", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Signature")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Signature", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Content-Sha256", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Date")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Date", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Credential")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Credential", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Security-Token")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Security-Token", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Algorithm")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Algorithm", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-SignedHeaders", valid_593307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593309: Call_StartLifecyclePolicyPreview_593297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ## 
  let valid = call_593309.validator(path, query, header, formData, body)
  let scheme = call_593309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593309.url(scheme.get, call_593309.host, call_593309.base,
                         call_593309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593309, url, valid)

proc call*(call_593310: Call_StartLifecyclePolicyPreview_593297; body: JsonNode): Recallable =
  ## startLifecyclePolicyPreview
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ##   body: JObject (required)
  var body_593311 = newJObject()
  if body != nil:
    body_593311 = body
  result = call_593310.call(nil, nil, nil, nil, body_593311)

var startLifecyclePolicyPreview* = Call_StartLifecyclePolicyPreview_593297(
    name: "startLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview",
    validator: validate_StartLifecyclePolicyPreview_593298, base: "/",
    url: url_StartLifecyclePolicyPreview_593299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593312 = ref object of OpenApiRestCall_592364
proc url_TagResource_593314(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593315 = header.getOrDefault("X-Amz-Target")
  valid_593315 = validateParameter(valid_593315, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.TagResource"))
  if valid_593315 != nil:
    section.add "X-Amz-Target", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Signature")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Signature", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Content-Sha256", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Date")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Date", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Credential")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Credential", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Security-Token")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Security-Token", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Algorithm")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Algorithm", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-SignedHeaders", valid_593322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593324: Call_TagResource_593312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_593324.validator(path, query, header, formData, body)
  let scheme = call_593324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593324.url(scheme.get, call_593324.host, call_593324.base,
                         call_593324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593324, url, valid)

proc call*(call_593325: Call_TagResource_593312; body: JsonNode): Recallable =
  ## tagResource
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ##   body: JObject (required)
  var body_593326 = newJObject()
  if body != nil:
    body_593326 = body
  result = call_593325.call(nil, nil, nil, nil, body_593326)

var tagResource* = Call_TagResource_593312(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.TagResource",
                                        validator: validate_TagResource_593313,
                                        base: "/", url: url_TagResource_593314,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593327 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593329(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593328(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593330 = header.getOrDefault("X-Amz-Target")
  valid_593330 = validateParameter(valid_593330, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UntagResource"))
  if valid_593330 != nil:
    section.add "X-Amz-Target", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Signature")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Signature", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Content-Sha256", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Date")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Date", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Credential")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Credential", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Security-Token")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Security-Token", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Algorithm")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Algorithm", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-SignedHeaders", valid_593337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593339: Call_UntagResource_593327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_593339.validator(path, query, header, formData, body)
  let scheme = call_593339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593339.url(scheme.get, call_593339.host, call_593339.base,
                         call_593339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593339, url, valid)

proc call*(call_593340: Call_UntagResource_593327; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_593341 = newJObject()
  if body != nil:
    body_593341 = body
  result = call_593340.call(nil, nil, nil, nil, body_593341)

var untagResource* = Call_UntagResource_593327(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UntagResource",
    validator: validate_UntagResource_593328, base: "/", url: url_UntagResource_593329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadLayerPart_593342 = ref object of OpenApiRestCall_592364
proc url_UploadLayerPart_593344(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UploadLayerPart_593343(path: JsonNode; query: JsonNode;
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
  var valid_593345 = header.getOrDefault("X-Amz-Target")
  valid_593345 = validateParameter(valid_593345, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UploadLayerPart"))
  if valid_593345 != nil:
    section.add "X-Amz-Target", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-Signature")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Signature", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Content-Sha256", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Date")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Date", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Credential")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Credential", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Security-Token")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Security-Token", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Algorithm")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Algorithm", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-SignedHeaders", valid_593352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593354: Call_UploadLayerPart_593342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_593354.validator(path, query, header, formData, body)
  let scheme = call_593354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593354.url(scheme.get, call_593354.host, call_593354.base,
                         call_593354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593354, url, valid)

proc call*(call_593355: Call_UploadLayerPart_593342; body: JsonNode): Recallable =
  ## uploadLayerPart
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_593356 = newJObject()
  if body != nil:
    body_593356 = body
  result = call_593355.call(nil, nil, nil, nil, body_593356)

var uploadLayerPart* = Call_UploadLayerPart_593342(name: "uploadLayerPart",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UploadLayerPart",
    validator: validate_UploadLayerPart_593343, base: "/", url: url_UploadLayerPart_593344,
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
